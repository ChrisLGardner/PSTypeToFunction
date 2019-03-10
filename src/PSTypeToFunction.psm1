$script:PSModuleRoot = $PSScriptRoot
. (Get-ChildItem "$PSScriptRoot\Public\*.ps1")
. (Get-ChildItem "$PSScriptRoot\Private\*.ps1")