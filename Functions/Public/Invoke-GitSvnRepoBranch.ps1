function Invoke-GitSvnRepoBranch {
    [CmdletBinding()]
    Param(
        <# Complete path to the repository to update #>
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-PathIsGitRepository $_ })]
        [System.IO.DirectoryInfo]
        $RepositoryPath,
        <# Perfrom a dry run? #>
        [Parameter(Mandatory = $false)]
        [Alias("n")]
        [switch]$DryRun,
        <# The where the branch will go in SVN as dictated by your .config in .git #>
        [Parameter(Mandatory = $true)]
        [String]$DestinationBranch,
        <# What should the branch be called? #>
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                if ($_ -match "^(?!.*/\.)(?!.*\.\.)(?!/)(?!.*//)(?!.*@\{)(?!@$)(?!.*\\)[^\000-\037\177 ~^:?*[]+/[^\000-\037\177 ~^:?*[]+(?<!\.lock)(?<!/)(?<!\.)$") {
                    throw "Git branch names must abide by the following rules:
                - No path component may begin with a dot (.) (ex: foo/.bar)
                - No path component may have a dobule dot (..) (ex: foo../bar)
                - No ASCII control characters, tilde (~), caret (^), colon (:), or space ( ) anywhere
                - Does not end with a slash (/)
                - Does not end with .lock (ex: foo/bar.lock)
                - Does not contain a backslash (\)"
                }
                else {
                    return $true
                }
            })]
        [String]$BranchName,
        [Parameter(Mandatory = $false)]
        [Alias("m")]
        [String]$BranchCommitMessage
    )
    Begin {
        Push-Location
        Set-Location $RepositoryPath
        $CurrentBranch = (Get-GitStatus).Branch
        Write-Host "Branching GitSvn repository from $CurrentBranch to $BranchName (SVN Destination $DestinationBranch) at $RepositoryPath" -ForegroundColor Yellow
        $cmd = "git svn branch"
        if ($DryRun) {
            $cmd = $cmd + " -n"
        }
        $cmd = $cmd + " $BranchName --destination $DestinationBranch"
        if ($BranchCommitMessage) {
            $cmd = $cmd + " -m `"$BranchCommitMessage`""
        }
        Write-Debug "Will run command $cmd"
    }
    Process {
        try {
            Invoke-Expression $cmd
        }
        finally {
            Write-Host "Done!" -ForegroundColor Green
        }
    }
    End {
        Pop-Location
    }
}
