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
        if ($BranchRoots) {
            $ReplaceString += "/($($BranchRoots -join "|"))/"
        }
        # Get the tracking branch (if we're on a branch)
        $TrackingBranch = (Invoke-Expression "git svn info" | Out-String | Split-PSUString -With "`n" | Where-Object { $_ -match "URL" }) -replace $ReplaceString, ""
        # If the tracking branch has 'URL' at the beginning, then the sed wasn't successful and
        # # we'll fall back to the svn-remote config option
        if (!($TrackingBranch -match "URL.*" )) {
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
