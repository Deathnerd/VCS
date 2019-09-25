function Invoke-GitSvnRepoCommit {
    [CmdletBinding()]
    Param (
        # Complete path to the repository to update
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-PathIsGitRepository $_})]
        [System.IO.DirectoryInfo]
        $RepositoryPath,
        # Do a dry run of the commit
        [Parameter(Mandatory = $false, HelpMessage = "Do a dry run of the commit")]
        [switch]
        $DryRun,
        # Rebase while committing
        [Parameter(Mandatory = $false, HelpMessage = "Rebase while committing")]
        [switch]
        $NoRebase
    )

    Begin {
        Push-Location
        Set-Location $RepositoryPath
        if ($DryRun) {
            Write-Host "Doing a dry run of a commit to $RepositoryPath" -ForegroundColor Yellow
        }
        else {
            Write-Host "Committing to repository $RepositoryPath" -ForegroundColor Yellow
        }
        $status = Get-GitStatus
        $needsStash = $status.Working.Length -gt 0 -or $status.Index.Length -gt 0
        if ($needsStash) {
            git stash
        }
        else {
            Write-Host "No stash needed" -ForegroundColor Yellow
        }
    }

    Process {
        if ($DryRun) {
            git svn dcommit --dry-run
        }
        elseif ($NoRebase) {
            git svn dcommit --no-rebase
        }
        else {
            git svn dcommit
        }
    }

    End {
        if ($needsStash) {
            Write-Host "Un-stashing changes..." -ForegroundColor Yellow
            git stash pop
        }
        Pop-Location
    }
}
