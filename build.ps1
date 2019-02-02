param (
    $Task
)

if (-not (Get-Module PSdepend -List)) {
    Install-Module -Name PSDepend -Scope CurrentUser -Force -Confirm:$false
}

Invoke-PSDepend -Force -Confirm:$false

# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList $task
