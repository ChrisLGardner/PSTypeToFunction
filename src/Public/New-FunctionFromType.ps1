Function New-FunctionFromType {
    [cmdletbinding(DefaultParameterSetName = 'TypeName')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [ValidateSet('All', 'New', 'Remove', 'Get', 'Set')]
        [string[]]$Type = "All",
        [string]$Path = $PWD,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'TypeName')]
        [String]$TypeName,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Object]$InputObject,
        [string]$Template = "Default",
        [ValidateSet("Low", "Medium", "High")]
        [string]$ConfirmImpact = "Low"
    )

    begin {
        function Add-String {
            [cmdletbinding()]
            param(
                [string[]]$String,
                [switch]$Fresh
            )
            if ($Fresh -or -not $sb) {
                $sb = New-Object -TypeName System.Text.StringBuilder
            }
            $sb.Append($String)
        }
        if ($Type -eq "All") {
            $Type = "New", "Remove", "Get", "Set"
        }

        if ($Template -eq "Default") {
            $Template = "$script:PSModuleRoot\Private\template.txt"
        }
        elseif ($Template -eq "dbatools") {
            $Template = "$script:PSModuleRoot\Private\template-dbatools.txt"
        }
        else {

        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'TypeName') {
            $Properties = @(
                ($TypeName -as [Type]).GetProperties() | Where-Object { $_.CanWrite }
                ($TypeName -as [Type]).GetFields()     | Where-Object { -not $_.Attributes.HasFlag([System.Reflection.FieldAttributes]::InitOnly) }
            )
        }
        else {
            $Properties = @(
                $InputObject.GetProperties() | Where-Object { $_.CanWrite }
                $InputObject.GetFields()     | Where-Object { -not $_.Attributes.HasFlag([System.Reflection.FieldAttributes]::InitOnly) }
            )
        }

        foreach ($typename in $Type) {
            Add-String -Fresh -String "Function $Name {
    <#"

            Add-String -String "
#>
    [CmdletBinding()]
    param (
 "
            foreach ($Property in $Properties) {
                if ($Property.PropertyType.Name -as [Type]) {
                    $type = $Property.PropertyType.Name
                }
                else {
                    $type = $Property.PropertyType.FullName
                }
                Add-String -String "     [{0}]`${1},`n`n" -f $type, $Property.Name
            }
            Add-String -String "
    )
}"

            if ($Passthru) {
                $FunctionDefinition
            }
            else {
                $FunctionDefinition | Set-Content -Path "$Path\$Name"
            }
        }
    }
}
