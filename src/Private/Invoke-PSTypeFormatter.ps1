function Invoke-PSTypeFormatter {
    <#
    .SYNOPSIS
        Helps formatting function files to dbatools' standards

    .DESCRIPTION
        Uses PSSA's Invoke-Formatter to format the target files and saves it without the BOM.

    .PARAMETER Path
        The path to the ps1 file that needs to be formatted

    .NOTES
        Author: Simone Bizzotto

    .EXAMPLE
        PS C:\> Invoke-PSTypeFormatter -Path C:\dbatools\functions\Get-DbaDatabase.ps1

        Reformats C:\dbatools\functions\Get-DbaDatabase.ps1 to dbatools' standards

    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [object[]]$Path
    )
    begin {
        $CBHRex = [regex]'(?smi)\s+<#[^#]*#>'
        $CBHStartRex = [regex]'(?<spaces>[ ]+)<#'
        $CBHEndRex = [regex]'(?<spaces>[ ]*)#>'
    }
    process {
        $HasInvokeFormatter = $null -ne (Get-Command Invoke-Formatter -ErrorAction SilentlyContinue).Version
        if (-not ($HasInvokeFormatter)) {
            Write-Warning -Message "You need a recent version of PSScriptAnalyzer installed"
            return
        }
        foreach ($p in $Path) {
            try {
                $realPath = (Resolve-Path -Path $p -ErrorAction Stop).Path
            }
            catch {
                Write-Warning -Message "Cannot find or resolve $p"
                continue
            }

            $content = Get-Content -Path $realPath -Raw -Encoding UTF8
            #strip ending empty lines
            $content = $content -replace "(?s)`r`n\s*$"
            try {
                $content = Invoke-Formatter -ScriptDefinition $content -Settings CodeFormattingOTBS -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Unable to format $p"
            }
            #match the ending indentation of CBH with the starting one, see #4373
            $CBH = $CBHRex.Match($content).Value
            if ($CBH) {
                #get starting spaces
                $startSpaces = $CBHStartRex.Match($CBH).Groups['spaces']
                if ($startSpaces) {
                    #get end
                    $newCBH = $CBHEndRex.Replace($CBH, "$startSpaces#>")
                    if ($newCBH) {
                        #replace the CBH
                        $content = $content.Replace($CBH, $newCBH)
                    }
                }
            }
            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
            $realContent = @()
            #trim whitespace lines
            foreach ($line in $content.Split("`n")) {
                $realContent += $line.TrimEnd()
            }
            [System.IO.File]::WriteAllText($realPath, ($realContent -Join "`r`n"), $Utf8NoBomEncoding)
        }
    }
}