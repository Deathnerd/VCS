function Test-PathIsGitRepository {
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param (
        # Specifies the path to validate as a git repository
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to the possible repository location")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [string]
        $RepositoryPath
    )
    Process {
        if (!(Test-Path $RepositoryPath -Type Container)) {
            throw "$RepositoryPath is not a valid path"
            return $false
        }
        Push-Location
        Set-Location $RepositoryPath
        if (!(Get-GitDirectory)) {
            throw "$RespositoryPath is not a valid git repository (does not contain a .git/ folder)"
            Pop-Location
            return $false
        }
        Pop-Location
        return $true
    }
}