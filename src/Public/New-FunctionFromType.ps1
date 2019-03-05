Function New-FunctionFromType {
    <#
.SYNOPSIS
Converts .NET types into PowerShell commands

.DESCRIPTION
Converts .NET types into PowerShell commands

.PARAMETER Verb
The verb to be generated. "All" by default. Options include All, New, Get, Set, and Remove.

.PARAMETER Path
The Path to the directory where the commands will be created. Present working directory by default.

.PARAMETER TypeName
The full name of the .NET type

.PARAMETER InputObject
Accepts [Type] input

.PARAMETER Template
The template to use. Uses a default template by default. To use the dbatools template, specify dbatools.

.PARAMETER ConfirmImpact
The confirmation impact. Low by default. Options include Low, Medium and High.

.PARAMETER Prefix
If your module uses a prefix (like Dba, Sql, Az, etc), use this Prefix.

.PARAMETER Passthru
Output code to console instead of writing to disk.

.PARAMETER ExcludeProperty
Exclude properties you don't want.

.EXAMPLE
 PS> New-FunctionFromType -TypeName Microsoft.SqlServer.Management.Smo.Mail.MailProfile -Prefix Dba -ExcludeProperty UserData, Parent

 Generates 4 new files: New-DbaMailProfile, Get-DbaMailProfile, Set-DbaMailProfile, Remove-DbaMailProfile. Excludes UserData and Parent.

#>

    [cmdletbinding(DefaultParameterSetName = 'TypeName')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [ValidateSet('All', 'New', 'Remove', 'Get', 'Set')]
        [String[]]$Verb = "All",
        [String]$Path = $PWD,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'TypeName')]
        [String]$TypeName,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Object]$InputObject,
        [String]$Template = "Default",
        [ValidateSet("Low", "Medium", "High")]
        [String]$ConfirmImpact = "Low",
        [String]$Prefix,
        [Switch]$Passthru,
        [String[]]$ExcludeProperty
    )

    begin {
        if ($Verb -eq "All") {
            $Verb = "New", "Remove", "Get", "Set"
        }

        if ($Template -eq "Default") {
            $Template = Resolve-Path -Path "$script:PSModuleRoot\Private\template.txt"
        }
        elseif ($Template -eq "dbatools") {
            $Template = Resolve-Path -Path "$script:PSModuleRoot\Private\template-dbatools.txt"
        }
        else {
            if (-not (Test-Path -Path $Template)) {
                throw "Can't find $Template"
            }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -ne 'TypeName') {
            $TypeName = $InputObject.GetType().Name
        }

        $properties = @(
            ($TypeName -as [Type]).GetProperties() | Where-Object { $_.CanWrite }
            ($TypeName -as [Type]).GetFields()     | Where-Object { -not $_.Attributes.HasFlag([System.Reflection.FieldAttributes]::InitOnly) }
        )

        if ($ExcludeProperty) {
            $properties = $properties | Where-Object Name -notin $ExcludeProperty
        }

        foreach ($verbname in $Verb) {
            $text = Get-Content -Path $Template
            $shortname = ($TypeName -split "\.")[-1]
            $name = "$verbname-$Prefix" + $shortname
            $text = $text.Replace("--name--", $name)
            $text = $text.Replace("--confirmimpact--", $ConfirmImpact)
            $params = $help = $process = @()
            $filename = "$Path\$name.ps1"

            foreach ($Property in $Properties) {
                if ($Property.PropertyType.Name -as [Type]) {
                    $type = $Property.PropertyType.Name
                }
                else {
                    $type = $Property.PropertyType.FullName
                }
                $params += "     [{0}]`${1}" -f $type, $Property.Name
                $help += "    .PARAMETER $($Property.Name)`n`n    `n`n"
                $process += "`$object.$($Property.Name) = `$$($Property.Name)"
            }

            $text = $text.Replace("--params--", ($params -join ",`n"))
            $text = $text.Replace("--help--", $help)
            $text = $text.Replace("--process--", ($process -join "`n"))
            $text = $text.Replace("--fullname--", $TypeName)

            if ($Passthru) {
                $text
            }
            else {
                $text | Set-Content -Path $filename
                Get-ChildItem $filename
            }
        }
    }
}
