function Get-GitBranches {
    [CmdletBinding()]
    [OutputType([String[]])]
    Param (
        # Specifies the path to validate as a git repository
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to the possible repository location")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [String]$RepositoryPath,
        [Switch]$Remote
    )
    Process {
        if (!(Test-Path $RepositoryPath -Type Container)) {
            throw "$RepositoryPath is not a valid path"
            return @()
        }
        Push-Location
        Set-Location $RepositoryPath
        if (!(Get-GitDirectory)) {
            throw "$RespositoryPath is not a valid git repository (does not contain a .git/ folder)"
            Pop-Location
            return @()
        }
        if ($Remote) {
            $Branches = (git branch -r --no-color --no-merged)
        }
        else {
            $Branches = (git branch --no-color --no-merged)
        }
        Pop-Location
        return ($Branches | Where-Object { $_ -notmatch '^\* ' } | ForEach-Object { $_.Trim() })
    }
}