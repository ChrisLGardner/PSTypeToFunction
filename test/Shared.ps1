# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleManifestPath = "$PSScriptRoot\..\Release\PSTypeToFunction\PSTypeToFunction.psd1"

if (!$SuppressImportModule) {
    # -Scope Global is needed when running tests from inside of psake, otherwise
    # the module's functions cannot be found in the PSTypeToFunction\ namespace
    Import-Module $ModuleManifestPath -Scope Global
}

