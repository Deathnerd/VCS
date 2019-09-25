function Invoke-GitSvnRepoUpdate {
    [CmdletBinding()]
    Param (
        <# Complete path to the repository to update #>
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-PathIsGitRepository $_})]
        [System.IO.DirectoryInfo]
        $RepositoryPath,
        <# Do svn rebase #>
        [switch]
        $Rebase,
        <# If set, merge commits will be replayed instead of committed as-is #>
        [switch]
        $ReplayMerge,
        <# Which branch do you want to update? #>
        [Parameter(HelpMessage = "The branch to update")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -eq "master" -or (Get-GitBranches $RepositoryPath).Contains($_) })]
        [String]
        $Branch = "master"
    )
    Begin {
        Push-Location
        Set-Location $RepositoryPath
        $CurrentBranch = (Get-GitStatus).Branch
        $status = Get-GitStatus
        $needsStash = $status.Working.Length -gt 0 -or $status.Index.Length -gt 0
        if ($needsStash) {
            Write-Host "Stashing uncommitted changes..." -ForegroundColor Yellow
            git stash
        }
        else {
            Write-Host "No stash needed" -ForegroundColor Yellow
        }
        if ($CurrentBranch -ne $Branch) {
            git checkout $Branch
        }
        Write-Host "Updating GitSvn repository at $RepositoryPath on branch $Branch" -ForegroundColor Yellow
    }
    Process {
        try {
            if (-not $Rebase) {
                Write-Host "Fetching latest..." -ForegroundColor Yellow
                git svn fetch
            }
            else {
                Write-Host "Fetching and rebasing..." -ForegroundColor Yellow
                if ($ReplayMerge) {
                    git svn rebase
                }
                else {
                    git svn rebase --preserve-merges
                }
            }
        }
        finally {
            Write-Host "Done!" -ForegroundColor Green
        }
    }
    End {
        if ($CurrentBranch -ne (Get-GitStatus).Branch) {
            git checkout $CurrentBranch
        }
        if ($needsStash) {
            Write-Host "Un-stashing changes..." -ForegroundColor Yellow
            git stash pop
        }
        Pop-Location
    }
}
