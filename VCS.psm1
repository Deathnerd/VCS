$Functions = @{
    Public  = Get-ChildItem "$PSScriptRoot\Functions\Public\*.ps1" -File
    Private = Get-ChildItem "$PSScriptRoot\Functions\Private\*.ps1" -File
}
($Functions.Public + $Functions.Private) | ForEach-Object {
    . "$($_.FullName)"
}
# TODO: Consolidate the gitsvn functions into one Invoke-GitSvnRepo function
Export-ModuleMember -Function ($Functions.Public.BaseName) -Variable *