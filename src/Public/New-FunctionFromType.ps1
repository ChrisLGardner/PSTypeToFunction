Function New-FunctionFromType {
    [cmdletbinding(DefaultParameterSetName = 'TypeName')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [ValidateSet('All', 'New', 'Remove', 'Get', 'Set')]
        [string[]]$Verb = "All",
        [string]$Path = $PWD,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'TypeName')]
        [String]$TypeName,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Object]$InputObject,
        [string]$Template = "Default",
        [ValidateSet("Low", "Medium", "High")]
        [string]$ConfirmImpact = "Low",
        [String]$Prefix
    )

    begin {
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
        if ($PSCmdlet.ParameterSetName -ne 'TypeName') {
            $TypeName = $InputObject.GetType().Name
        }

        $properties = @(
            ($TypeName -as [Type]).GetProperties() | Where-Object { $_.CanWrite }
            ($TypeName -as [Type]).GetFields()     | Where-Object { -not $_.Attributes.HasFlag([System.Reflection.FieldAttributes]::InitOnly) }
        )

        foreach ($v in $verb) {
            $name = "$v-$Prefix" + $TypeName
            $filename = "$Path\$name.ps1"

            foreach ($Property in $Properties) {
                if ($Property.PropertyType.Name -as [Type]) {
                    $type = $Property.PropertyType.Name
                }
                else {
                    $type = $Property.PropertyType.FullName
                }
                Add-String -String "     [{0}]`${1},`n`n" -f $type, $Property.Name
            }

            if ($Passthru) {
                $FunctionDefinition
            }
            else {
                $FunctionDefinition | Set-Content -Path $filename
            }
        }
    }
}
