@{
    PSDependOptions = @{
        Target = '.\Dependencies'
        AddToPath = $true
    }
    Configuration = 'Latest'
    Pester = @{
        Name = 'Pester'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    PlatyPS = 'Latest'
    PSScriptAnalyzer = 'Latest'
}
