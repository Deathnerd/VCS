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
        if($Remote) {
            $Branches = (git branch -r --no-color --no-merged)
        } else {
            $Branches = (git branch --no-color --no-merged)
        }
        Pop-Location
        return ($Branches | Where-Object { $_ -notmatch '^\* ' } | ForEach-Object { $_.Trim() })
    }
}

class ValidatePathIsGitRepo : Attribute {

}

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

# TODO: Consolidate the gitsvn functions into one Invoke-GitSvnRepo function
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
        $Rebase
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
        elseif ($Rebase) {
            git svn dcommit
        }
        else {
            git svn dcommit --no-rebase
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

function Invoke-GitSvnRepoUpdate {
    [CmdletBinding()]
    Param (
        <# Complete path to the repository to update #>
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-PathIsGitRepository $_})]
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
        [ValidateScript({ $_ -eq "master" -or (Get-GitBranches $RepositoryPath).Contains($_) })]
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
        } else {
            Write-Host "No stash needed" -ForegroundColor Yellow
        }
        if($CurrentBranch -ne $Branch) {
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
        if($CurrentBranch -ne (Get-GitStatus).Branch) {
            git checkout $CurrentBranch
        }
        if ($needsStash) {
            Write-Host "Un-stashing changes..." -ForegroundColor Yellow
            git stash pop
        }
        Pop-Location
    }
}

function Invoke-GitSvnRepoBranch {
    [CmdletBinding()]
    Param(
        <# Complete path to the repository to update #>
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("Repo")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-PathIsGitRepository $_ })]
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
        [ValidateScript({
            if($_ -match "^(?!.*/\.)(?!.*\.\.)(?!/)(?!.*//)(?!.*@\{)(?!@$)(?!.*\\)[^\000-\037\177 ~^:?*[]+/[^\000-\037\177 ~^:?*[]+(?<!\.lock)(?<!/)(?<!\.)$") {
                throw "Git branch names must abide by the following rules:
                - No path component may begin with a dot (.) (ex: foo/.bar)
                - No path component may have a dobule dot (..) (ex: foo../bar)
                - No ASCII control characters, tilde (~), caret (^), colon (:), or space ( ) anywhere
                - Does not end with a slash (/)
                - Does not end with .lock (ex: foo/bar.lock)
                - Does not contain a backslash (\)"
            } else {
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
        if($DryRun) {
            $cmd = $cmd + " -n"
        }
        $cmd = $cmd + " $BranchName --destination $DestinationBranch"
        if($BranchCommitMessage) {
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

function Convert-GitDiffToSvnDiff {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [System.IO.DirectoryInfo]$GitRepoLocation = "C:\Hydrogen\hydrogen\",
        [Parameter()]
        [System.Uri]$SVNRootRepositoryUrl = "https://svn.lab.opentext.com/svn/ipg-esx-hydrogen/hydrogen",
        [string[]]$BranchRoots = @("Sandbox", "branches"),
        [Parameter()]
        [string]$OutFile = (Join-Path $GitRepoLocation "converted.patch")
    )
    Process {
        $ReplaceString = ".*$SVNRootRepositoryUrl"
        if($BranchRoots) {
            $ReplaceString += "/($($BranchRoots -join "|"))/"
        }
        # Get the tracking branch (if we're on a branch)
        $TrackingBranch = (Invoke-Expression "git svn info" | Out-String | Split-PSUString -With "`n" | Where-Object { $_ -match "URL" }) -replace $ReplaceString, ""
        # If the tracking branch has 'URL' at the beginning, then the sed wasn't successful and
        # # we'll fall back to the svn-remote config option
        if(!($TrackingBranch -match "URL.*" )) {
            $TrackingBranch = (Invoke-Expression "git config --get svn-remote.svn.fetch") -replace ".*:refs/remotes/", ""
        }

        
    }
#     #!/bin/bash
# #
# # git-svn-diff originally by (http://mojodna.net/2009/02/24/my-work-git-workflow.html)
# # modified by mike@mikepearce.net
# #
# # Generate an SVN-compatible diff against the tip of the tracking branch

# # Get the tracking branch (if we're on a branch)
# TRACKING_BRANCH=`git svn info | grep URL | sed -e 's/.*\/branches\///'`

# # If the tracking branch has 'URL' at the beginning, then the sed wasn't successful and
# # we'll fall back to the svn-remote config option
# if [[ "$TRACKING_BRANCH" =~ URL.* ]]
# then
#         TRACKING_BRANCH=`git config --get svn-remote.svn.fetch | sed -e 's/.*:refs\/remotes\///'`
# fi

# # Get the highest revision number
# REV=`git svn find-rev $(git rev-list --date-order --max-count=1 $TRACKING_BRANCH)`

# # Then do the diff from the highest revition on the current branch
# git diff --no-prefix $(git rev-list --date-order --max-count=1 $TRACKING_BRANCH) $* |
# sed -e "s/^+++ .*/&     (working copy)/" -e "s/^--- .*/&        (revision $REV)/" \
# -e "s/^diff --git [^[:space:]]*/Index:/" \
# -e "s/^index.*/===================================================================/"
}

Export-ModuleMember -Function *-*