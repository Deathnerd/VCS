$ModuleName = ([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName
$ConfigPath = Join-Path (Join-Path $env:USERPROFILE ".config") $ModuleName
if (!(Test-Path $ConfigPath)) {
    New-Item -ItemType Directory -Path $ConfigPath | Out-Null
}
if ($Null -eq (Get-Variable "${ModuleName}ConfigLocation" -ErrorAction SilentlyContinue)) {
    New-Variable -Name "${ModuleName}ConfigLocation" -Description "The where $ModuleName configs are stored"  -Value ($ConfigPath -as [IO.DirectoryInfo]) -Scope Script
}
$Functions = @{
    Public  = Get-ChildItem "$PSScriptRoot\Functions\Public\*.ps1" -File
    Private = Get-ChildItem "$PSScriptRoot\Functions\Private\*.ps1" -File
}
($Functions.Public + $Functions.Private) | ForEach-Object {
    . "$($_.FullName)"
}
# TODO: Consolidate the gitsvn functions into one Invoke-GitSvnRepo function
Export-ModuleMember -Function ($Functions.Public.BaseName) -Variable *