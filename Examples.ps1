<#
.SYNOPSIS
    Example usage of the PSYahooFinance-AI PowerShell module

.DESCRIPTION
    This script demonstrates how to use the PSYahooFinance-AI module
    to fetch financial data from Yahoo Finance.

.NOTES
    Make sure to import the module first:
    Import-Module .\PSYahooFinance-AI.psd1
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot 'PSYahooFinance-AI.psd1'
Import-Module $modulePath -Force

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "PSYahooFinance-AI PowerShell Module - Examples" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

#region Example 1: Get Current Stock Price
Write-Host "`n=== Example 1: Current Stock Price ===" -ForegroundColor Green
$symbols = @('AAPL', 'MSFT', 'NVDA', 'TSLA')
foreach ($symbol in $symbols) {
    $price = Get-CurrentStockPrice -Symbol $symbol
    Write-Host "$symbol`: $price"
}
#endregion

#region Example 2: Get Company Info
Write-Host "`n=== Example 2: Company Information ===" -ForegroundColor Green
$companyInfo = Get-CompanyInfo -Symbol 'AAPL' -AsObject
Write-Host "Company: $($companyInfo.Name)"
Write-Host "Symbol: $($companyInfo.Symbol)"
Write-Host "Exchange: $($companyInfo.Exchange)"
Write-Host "Current Price: $($companyInfo.'Current Stock Price')"
Write-Host "52 Week High: $($companyInfo.'52 Week High')"
Write-Host "52 Week Low: $($companyInfo.'52 Week Low')"
#endregion

#region Example 3: Get Stock Fundamentals
Write-Host "`n=== Example 3: Stock Fundamentals ===" -ForegroundColor Green
$fundamentals = Get-StockFundamentals -Symbol 'NVDA' -AsObject
Write-Host "Symbol: $($fundamentals.symbol)"
Write-Host "Company: $($fundamentals.company_name)"
Write-Host "Current Price: $($fundamentals.current_price)"
Write-Host "52 Week High: $($fundamentals.'52_week_high')"
Write-Host "52 Week Low: $($fundamentals.'52_week_low')"
Write-Host "% From 52 Week High: $($fundamentals.pct_from_52wk_high)%"
Write-Host "% From 52 Week Low: $($fundamentals.pct_from_52wk_low)%"
#endregion

#region Example 4: Get Historical Prices
Write-Host "`n=== Example 4: Historical Prices (Last 5 days) ===" -ForegroundColor Green
$history = Get-HistoricalStockPrices -Symbol 'AAPL' -Period '5d' -AsObject
$history | Select-Object Date, Open, High, Low, Close, Volume | Format-Table -AutoSize
#endregion

#region Example 5: Get Price Analysis (Analyst Recommendations)
Write-Host "`n=== Example 5: Price Analysis ===" -ForegroundColor Green
$analysis = Get-AnalystRecommendations -Symbol 'TSLA' -AsObject
Write-Host "Symbol: $($analysis.symbol)"
Write-Host "Company: $($analysis.companyName)"
Write-Host "Current Price: $($analysis.currentPrice)"
Write-Host "Trend: $($analysis.trend)"
Write-Host "Technical Signal: $($analysis.technicalSignal)"
Write-Host "SMA 20: $($analysis.sma20)"
Write-Host "SMA 50: $($analysis.sma50)"
Write-Host "5-Day Momentum: $($analysis.momentum5Day)%"
Write-Host "20-Day Momentum: $($analysis.momentum20Day)%"
#endregion

#region Example 6: Get Company News
Write-Host "`n=== Example 6: Company News ===" -ForegroundColor Green
$news = Get-CompanyNews -Symbol 'MSFT' -NumStories 3 -AsObject
foreach ($item in $news) {
    Write-Host "[$($item.providerPublishTime)] $($item.title)" -ForegroundColor Yellow
    Write-Host "  Publisher: $($item.publisher)"
    Write-Host ""
}
#endregion

#region Example 7: Get Key Financial Ratios
Write-Host "`n=== Example 7: Key Financial Metrics ===" -ForegroundColor Green
$ratios = Get-KeyFinancialRatios -Symbol 'GOOGL' -AsObject
Write-Host "Company: $($ratios.shortName)"
Write-Host "Price: $($ratios.regularMarketPrice)"
Write-Host "Day Change: $($ratios.dayChangePct)%"
Write-Host "YTD Return: $($ratios.ytdReturnPct)%"
Write-Host "Annualized Volatility: $($ratios.annualizedVolatilityPct)%"
Write-Host "52 Week High: $($ratios.fiftyTwoWeekHigh)"
Write-Host "52 Week Low: $($ratios.fiftyTwoWeekLow)"
#endregion

#region Example 8: Get Yearly Performance
Write-Host "`n=== Example 8: Yearly Performance ===" -ForegroundColor Green
$yearly = Get-IncomeStatements -Symbol 'AMZN' -AsObject
$yearly | Select-Object Year, 'Year Open', 'Year Close', 'Year High', 'Year Low', 'Year Return %' | Format-Table -AutoSize
#endregion

#region Example 9: Get Technical Indicators
Write-Host "`n=== Example 9: Technical Indicators (Last 5 days) ===" -ForegroundColor Green
$technical = Get-TechnicalIndicators -Symbol 'META' -Period '1mo' -AsObject
$technical | Select-Object -Last 5 Date, Open, High, Low, Close, Volume | Format-Table -AutoSize
#endregion

#region Example 10: Pipeline Support
Write-Host "`n=== Example 10: Pipeline Support ===" -ForegroundColor Green
$prices = 'AAPL', 'GOOGL', 'AMZN' | ForEach-Object {
    [PSCustomObject]@{
        Symbol = $_
        Price  = Get-CurrentStockPrice -Symbol $_
    }
}
$prices | Format-Table -AutoSize
#endregion

Write-Host ("`n" + ("=" * 60)) -ForegroundColor Cyan
Write-Host "Examples Complete!" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
