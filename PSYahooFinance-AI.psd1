@{
    # Script module or binary module file associated with this manifest
    RootModule        = 'PSYahooFinance-AI.psm1'
    
    # Version number of this module
    ModuleVersion     = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID              = '0601662b-f6ea-4c7f-86fd-4d97b9a58de3'
    
    # Author of this module
    Author            = 'Doug Finke'
    
    # Company or vendor of this module
    CompanyName       = 'Doug Finke'
    
    # Copyright statement for this module
    Copyright         = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'PowerShell module for getting financial data from Yahoo Finance. A port of the Python agno YFinanceTools toolkit.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-CurrentStockPrice',
        'Get-CompanyInfo',
        'Get-HistoricalStockPrices',
        'Get-StockFundamentals',
        'Get-IncomeStatements',
        'Get-KeyFinancialRatios',
        'Get-AnalystRecommendations',
        'Get-CompanyNews',
        'Get-TechnicalIndicators'
    )
    
    # Aliases to export from this module
    AliasesToExport   = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module
            Tags         = @('PowerShell', 'Finance', 'Stock', 'Yahoo', 'Investment', 'Trading', 'Market', 'YFinance')
            
            # A URL to the license for this module
            # LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri   = 'https://github.com/dfinke/PSYahooFinance-AI'
            
            # ReleaseNotes of this module
            ReleaseNotes = ''
        }
    }
}
