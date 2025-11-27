<#
.SYNOPSIS
    YFinanceTools PowerShell Module - A port of Python's YFinanceTools

.DESCRIPTION
    This module provides functions for getting financial data from Yahoo Finance.
    It is a PowerShell port of the Python agno YFinanceTools toolkit.

.NOTES
    Author: Ported from Python agno YFinanceTools
    Date: 2025-11-27
    Version: 1.0.0
#>

#region Private Helper Functions

function Get-ValueOrDefault {
    <#
    .SYNOPSIS
        Returns the value if not null, otherwise returns the default value.
        PowerShell 5.1 compatible alternative to ?? operator.
    #>
    param(
        [Parameter(Position = 0)]
        $Value,
        
        [Parameter(Position = 1)]
        $Default = 'N/A'
    )
    
    if ($null -ne $Value) {
        return $Value
    }
    return $Default
}

function Invoke-YahooFinanceV8Request {
    <#
    .SYNOPSIS
        Makes HTTP requests to Yahoo Finance V8 API for chart/historical data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Symbol,
        
        [Parameter()]
        [string]$Range = '1mo',
        
        [Parameter()]
        [string]$Interval = '1d'
    )
    
    try {
        $url = "https://query1.finance.yahoo.com/v8/finance/chart/$Symbol`?range=$Range&interval=$Interval"
        
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
        
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        return $response
    }
    catch {
        throw "Error fetching chart data from Yahoo Finance: $_"
    }
}

function Get-YahooFinanceQuote {
    <#
    .SYNOPSIS
        Gets basic quote data for a symbol using the v8 chart API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Symbol
    )
    
    try {
        $response = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range '1d' -Interval '1d'
        $result = $response.chart.result[0]
        $meta = $result.meta
        
        # Build a quote object from chart metadata
        return @{
            regularMarketPrice = $meta.regularMarketPrice
            currentPrice = $meta.regularMarketPrice
            previousClose = $meta.chartPreviousClose
            currency = $meta.currency
            symbol = $meta.symbol
            exchangeName = $meta.exchangeName
            fullExchangeName = $meta.fullExchangeName
            longName = $meta.longName
            shortName = $meta.shortName
            fiftyTwoWeekHigh = $meta.fiftyTwoWeekHigh
            fiftyTwoWeekLow = $meta.fiftyTwoWeekLow
            regularMarketDayHigh = $meta.regularMarketDayHigh
            regularMarketDayLow = $meta.regularMarketDayLow
            regularMarketVolume = $meta.regularMarketVolume
            instrumentType = $meta.instrumentType
        }
    }
    catch {
        throw "Error fetching quote for $Symbol`: $_"
    }
}

function Get-YahooFinanceSearch {
    <#
    .SYNOPSIS
        Searches Yahoo Finance for a symbol and returns news
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        
        [Parameter()]
        [int]$NewsCount = 5
    )
    
    try {
        $url = "https://query1.finance.yahoo.com/v1/finance/search?q=$Query&newsCount=$NewsCount&quotesCount=1"
        
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
        
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        return $response
    }
    catch {
        throw "Error searching Yahoo Finance: $_"
    }
}

#endregion

#region Public Functions

function Get-CurrentStockPrice {
    <#
    .SYNOPSIS
        Gets the current stock price for a given symbol

    .DESCRIPTION
        Use this function to get the current stock price for a given symbol.
        Returns the regular market price or current price.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .EXAMPLE
        Get-CurrentStockPrice -Symbol 'AAPL'
        Returns the current stock price for Apple Inc.

    .EXAMPLE
        'NVDA', 'TSLA' | Get-CurrentStockPrice
        Returns current stock prices for multiple symbols via pipeline
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol
    )
    
    process {
        try {
            Write-Verbose "Fetching current price for $Symbol"
            $quote = Get-YahooFinanceQuote -Symbol $Symbol
            
            $currentPrice = $quote.regularMarketPrice
            if (-not $currentPrice) {
                $currentPrice = $quote.currentPrice
            }
            
            if ($currentPrice) {
                return "{0:N4}" -f $currentPrice
            }
            else {
                return "Could not fetch current price for $Symbol"
            }
        }
        catch {
            return "Error fetching current price for $Symbol`: $_"
        }
    }
}

function Get-CompanyInfo {
    <#
    .SYNOPSIS
        Gets company information and overview for a given stock symbol

    .DESCRIPTION
        Use this function to get company information and overview for a given stock symbol.
        Returns a JSON string containing company profile and overview from available data.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER AsObject
        If specified, returns the data as a PowerShell object instead of JSON

    .EXAMPLE
        Get-CompanyInfo -Symbol 'AAPL'
        Returns company information for Apple Inc. as JSON

    .EXAMPLE
        Get-CompanyInfo -Symbol 'MSFT' -AsObject
        Returns company information for Microsoft as a PowerShell object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching company info for $Symbol"
            
            # Get data from v8 chart API
            $quote = Get-YahooFinanceQuote -Symbol $Symbol
            
            if (-not $quote) {
                return "Could not fetch company info for $Symbol"
            }
            
            $currency = Get-ValueOrDefault $quote.currency 'USD'
            
            $companyInfo = [ordered]@{
                Name                   = $quote.longName
                ShortName              = $quote.shortName
                Symbol                 = $quote.symbol
                'Current Stock Price'  = "$($quote.regularMarketPrice) $currency"
                Currency               = $currency
                Exchange               = $quote.fullExchangeName
                'Instrument Type'      = $quote.instrumentType
                '52 Week Low'          = $quote.fiftyTwoWeekLow
                '52 Week High'         = $quote.fiftyTwoWeekHigh
                'Day Low'              = $quote.regularMarketDayLow
                'Day High'             = $quote.regularMarketDayHigh
                'Previous Close'       = $quote.previousClose
                Volume                 = $quote.regularMarketVolume
            }
            
            if ($AsObject) {
                return [PSCustomObject]$companyInfo
            }
            
            return $companyInfo | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching company profile for $Symbol`: $_"
        }
    }
}

function Get-HistoricalStockPrices {
    <#
    .SYNOPSIS
        Gets historical stock prices for a given symbol

    .DESCRIPTION
        Use this function to get the historical stock price for a given symbol.
        Valid periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max
        Valid intervals: 1d, 5d, 1wk, 1mo, 3mo

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER Period
        The period for which to retrieve historical prices. Defaults to "1mo".
        Valid periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max

    .PARAMETER Interval
        The interval between data points. Defaults to "1d".
        Valid intervals: 1d, 5d, 1wk, 1mo, 3mo

    .PARAMETER AsObject
        If specified, returns the data as PowerShell objects instead of JSON

    .EXAMPLE
        Get-HistoricalStockPrices -Symbol 'AAPL'
        Returns 1 month of daily historical prices for Apple Inc.

    .EXAMPLE
        Get-HistoricalStockPrices -Symbol 'NVDA' -Period '3mo' -Interval '1wk'
        Returns 3 months of weekly historical prices for NVIDIA
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [ValidateSet('1d', '5d', '1mo', '3mo', '6mo', '1y', '2y', '5y', '10y', 'ytd', 'max')]
        [string]$Period = '1mo',
        
        [Parameter()]
        [ValidateSet('1d', '5d', '1wk', '1mo', '3mo')]
        [string]$Interval = '1d',
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching historical prices for $Symbol"
            
            $response = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range $Period -Interval $Interval
            
            $chart = $response.chart.result[0]
            $timestamps = $chart.timestamp
            $quote = $chart.indicators.quote[0]
            
            $historicalData = @{}
            
            for ($i = 0; $i -lt $timestamps.Count; $i++) {
                $timestamp = $timestamps[$i]
                $date = [DateTimeOffset]::FromUnixTimeSeconds($timestamp).DateTime.ToString('yyyy-MM-dd HH:mm:ss')
                
                $historicalData[$date] = [ordered]@{
                    Open      = $quote.open[$i]
                    High      = $quote.high[$i]
                    Low       = $quote.low[$i]
                    Close     = $quote.close[$i]
                    Volume    = $quote.volume[$i]
                }
            }
            
            if ($AsObject) {
                $result = @()
                foreach ($key in $historicalData.Keys | Sort-Object) {
                    $result += [PSCustomObject]@{
                        Date   = $key
                        Open   = $historicalData[$key].Open
                        High   = $historicalData[$key].High
                        Low    = $historicalData[$key].Low
                        Close  = $historicalData[$key].Close
                        Volume = $historicalData[$key].Volume
                    }
                }
                return $result
            }
            
            return $historicalData | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching historical prices for $Symbol`: $_"
        }
    }
}

function Get-StockFundamentals {
    <#
    .SYNOPSIS
        Gets fundamental data for a given stock symbol

    .DESCRIPTION
        Use this function to get fundamental data for a given stock symbol.
        Returns key metrics available from the chart API including 52-week range.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER AsObject
        If specified, returns the data as a PowerShell object instead of JSON

    .EXAMPLE
        Get-StockFundamentals -Symbol 'AAPL'
        Returns fundamental data for Apple Inc. as JSON

    .EXAMPLE
        Get-StockFundamentals -Symbol 'MSFT' -AsObject
        Returns fundamental data for Microsoft as a PowerShell object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching fundamentals for $Symbol"
            
            $quote = Get-YahooFinanceQuote -Symbol $Symbol
            
            # Calculate simple metrics from available data
            $currentPrice = $quote.regularMarketPrice
            $fiftyTwoWeekHigh = $quote.fiftyTwoWeekHigh
            $fiftyTwoWeekLow = $quote.fiftyTwoWeekLow
            
            # Calculate percentage from 52-week high/low
            $pctFrom52WeekHigh = if ($fiftyTwoWeekHigh -and $currentPrice) {
                [math]::Round((($currentPrice - $fiftyTwoWeekHigh) / $fiftyTwoWeekHigh) * 100, 2)
            } else { 'N/A' }
            
            $pctFrom52WeekLow = if ($fiftyTwoWeekLow -and $currentPrice) {
                [math]::Round((($currentPrice - $fiftyTwoWeekLow) / $fiftyTwoWeekLow) * 100, 2)
            } else { 'N/A' }
            
            $fundamentals = [ordered]@{
                symbol              = $Symbol
                company_name        = $quote.longName
                short_name          = $quote.shortName
                current_price       = $currentPrice
                currency            = $quote.currency
                exchange            = $quote.fullExchangeName
                instrument_type     = $quote.instrumentType
                previous_close      = $quote.previousClose
                day_high            = $quote.regularMarketDayHigh
                day_low             = $quote.regularMarketDayLow
                volume              = $quote.regularMarketVolume
                '52_week_high'      = $fiftyTwoWeekHigh
                '52_week_low'       = $fiftyTwoWeekLow
                pct_from_52wk_high  = $pctFrom52WeekHigh
                pct_from_52wk_low   = $pctFrom52WeekLow
            }
            
            if ($AsObject) {
                return [PSCustomObject]$fundamentals
            }
            
            return $fundamentals | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error getting fundamentals for $Symbol`: $_"
        }
    }
}

function Get-IncomeStatements {
    <#
    .SYNOPSIS
        Gets historical price data that can be used for income analysis

    .DESCRIPTION
        Use this function to get historical price data for a given stock symbol.
        Due to API restrictions, this returns historical price data for the past year
        which can be used for performance analysis.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER AsObject
        If specified, returns the data as a PowerShell object instead of JSON

    .EXAMPLE
        Get-IncomeStatements -Symbol 'AAPL'
        Returns yearly historical data for Apple Inc.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching historical financial data for $Symbol"
            
            # Get 5 years of monthly data for trend analysis
            $response = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range '5y' -Interval '1mo'
            
            $chart = $response.chart.result[0]
            $timestamps = $chart.timestamp
            $quote = $chart.indicators.quote[0]
            $meta = $chart.meta
            
            # Group by year
            $yearlyData = @{}
            
            for ($i = 0; $i -lt $timestamps.Count; $i++) {
                $timestamp = $timestamps[$i]
                $date = [DateTimeOffset]::FromUnixTimeSeconds($timestamp).DateTime
                $year = $date.Year.ToString()
                
                if (-not $yearlyData.ContainsKey($year)) {
                    $yearlyData[$year] = @{
                        Opens = @()
                        Closes = @()
                        Highs = @()
                        Lows = @()
                        Volumes = @()
                    }
                }
                
                if ($quote.open[$i]) { $yearlyData[$year].Opens += $quote.open[$i] }
                if ($quote.close[$i]) { $yearlyData[$year].Closes += $quote.close[$i] }
                if ($quote.high[$i]) { $yearlyData[$year].Highs += $quote.high[$i] }
                if ($quote.low[$i]) { $yearlyData[$year].Lows += $quote.low[$i] }
                if ($quote.volume[$i]) { $yearlyData[$year].Volumes += $quote.volume[$i] }
            }
            
            $financials = @{}
            
            foreach ($year in $yearlyData.Keys | Sort-Object -Descending) {
                $data = $yearlyData[$year]
                $avgClose = if ($data.Closes.Count -gt 0) { 
                    [math]::Round(($data.Closes | Measure-Object -Average).Average, 2) 
                } else { 'N/A' }
                
                $yearHigh = if ($data.Highs.Count -gt 0) { 
                    ($data.Highs | Measure-Object -Maximum).Maximum 
                } else { 'N/A' }
                
                $yearLow = if ($data.Lows.Count -gt 0) { 
                    ($data.Lows | Measure-Object -Minimum).Minimum 
                } else { 'N/A' }
                
                $totalVolume = if ($data.Volumes.Count -gt 0) { 
                    ($data.Volumes | Measure-Object -Sum).Sum 
                } else { 'N/A' }
                
                $yearOpen = if ($data.Opens.Count -gt 0) { $data.Opens[0] } else { 'N/A' }
                $yearClose = if ($data.Closes.Count -gt 0) { $data.Closes[-1] } else { 'N/A' }
                
                $yearReturn = if ($yearOpen -ne 'N/A' -and $yearClose -ne 'N/A' -and $yearOpen -gt 0) {
                    [math]::Round((($yearClose - $yearOpen) / $yearOpen) * 100, 2)
                } else { 'N/A' }
                
                $financials[$year] = [ordered]@{
                    'Year Open'        = $yearOpen
                    'Year Close'       = $yearClose
                    'Year High'        = $yearHigh
                    'Year Low'         = $yearLow
                    'Average Close'    = $avgClose
                    'Total Volume'     = $totalVolume
                    'Year Return %'    = $yearReturn
                }
            }
            
            if ($AsObject) {
                $results = @()
                foreach ($key in $financials.Keys | Sort-Object -Descending) {
                    $obj = [PSCustomObject]@{ Year = $key }
                    foreach ($prop in $financials[$key].Keys) {
                        $obj | Add-Member -NotePropertyName $prop -NotePropertyValue $financials[$key][$prop]
                    }
                    $results += $obj
                }
                return $results
            }
            
            return $financials | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching financial data for $Symbol`: $_"
        }
    }
}

function Get-KeyFinancialRatios {
    <#
    .SYNOPSIS
        Gets key financial metrics for a given stock symbol

    .DESCRIPTION
        Use this function to get key financial metrics for a given stock symbol.
        Returns metrics calculated from available price data.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER AsObject
        If specified, returns the data as a PowerShell object instead of JSON

    .EXAMPLE
        Get-KeyFinancialRatios -Symbol 'AAPL'
        Returns key financial ratios for Apple Inc.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching key financial ratios for $Symbol"
            
            $quote = Get-YahooFinanceQuote -Symbol $Symbol
            
            # Get historical data for volatility calculation
            $histResponse = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range '1y' -Interval '1d'
            $chart = $histResponse.chart.result[0]
            $histQuote = $chart.indicators.quote[0]
            
            # Calculate daily returns and volatility
            $closes = $histQuote.close | Where-Object { $_ -ne $null }
            $dailyReturns = @()
            for ($i = 1; $i -lt $closes.Count; $i++) {
                if ($closes[$i-1] -gt 0) {
                    $dailyReturns += ($closes[$i] - $closes[$i-1]) / $closes[$i-1]
                }
            }
            
            $avgDailyReturn = if ($dailyReturns.Count -gt 0) {
                [math]::Round(($dailyReturns | Measure-Object -Average).Average * 100, 4)
            } else { 'N/A' }
            
            # Calculate standard deviation (volatility)
            $volatility = 'N/A'
            if ($dailyReturns.Count -gt 1) {
                $avg = ($dailyReturns | Measure-Object -Average).Average
                $sumSquares = 0
                foreach ($r in $dailyReturns) {
                    $sumSquares += [math]::Pow($r - $avg, 2)
                }
                $stdDev = [math]::Sqrt($sumSquares / ($dailyReturns.Count - 1))
                $volatility = [math]::Round($stdDev * [math]::Sqrt(252) * 100, 2) # Annualized
            }
            
            # Calculate YTD return
            $currentYear = (Get-Date).Year
            $ytdResponse = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range 'ytd' -Interval '1mo'
            $ytdChart = $ytdResponse.chart.result[0]
            $ytdQuote = $ytdChart.indicators.quote[0]
            $ytdOpens = $ytdQuote.open | Where-Object { $_ -ne $null }
            $ytdCloses = $ytdQuote.close | Where-Object { $_ -ne $null }
            
            $ytdReturn = 'N/A'
            if ($ytdOpens.Count -gt 0 -and $ytdCloses.Count -gt 0 -and $ytdOpens[0] -gt 0) {
                $ytdReturn = [math]::Round((($ytdCloses[-1] - $ytdOpens[0]) / $ytdOpens[0]) * 100, 2)
            }
            
            $ratios = [ordered]@{
                # Price metrics
                symbol                   = $Symbol
                shortName                = $quote.shortName
                longName                 = $quote.longName
                regularMarketPrice       = $quote.regularMarketPrice
                previousClose            = $quote.previousClose
                currency                 = $quote.currency
                
                # Day metrics
                dayHigh                  = $quote.regularMarketDayHigh
                dayLow                   = $quote.regularMarketDayLow
                dayVolume                = $quote.regularMarketVolume
                
                # 52-week metrics
                fiftyTwoWeekHigh         = $quote.fiftyTwoWeekHigh
                fiftyTwoWeekLow          = $quote.fiftyTwoWeekLow
                
                # Calculated metrics
                avgDailyReturnPct        = $avgDailyReturn
                annualizedVolatilityPct  = $volatility
                ytdReturnPct             = $ytdReturn
                
                # Price change from previous close
                dayChangePct             = if ($quote.previousClose -gt 0) {
                    [math]::Round((($quote.regularMarketPrice - $quote.previousClose) / $quote.previousClose) * 100, 2)
                } else { 'N/A' }
            }
            
            if ($AsObject) {
                return [PSCustomObject]$ratios
            }
            
            return $ratios | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching key financial ratios for $Symbol`: $_"
        }
    }
}

function Get-AnalystRecommendations {
    <#
    .SYNOPSIS
        Gets price momentum analysis for a given stock symbol

    .DESCRIPTION
        Use this function to get price momentum analysis for a given stock symbol.
        Returns trend analysis based on moving averages and price momentum.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER AsObject
        If specified, returns the data as a PowerShell object instead of JSON

    .EXAMPLE
        Get-AnalystRecommendations -Symbol 'AAPL'
        Returns price analysis for Apple Inc.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching price analysis for $Symbol"
            
            # Get 6 months of daily data for analysis
            $response = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range '6mo' -Interval '1d'
            
            $chart = $response.chart.result[0]
            $meta = $chart.meta
            $quote = $chart.indicators.quote[0]
            
            $closes = @($quote.close | Where-Object { $_ -ne $null })
            $currentPrice = $meta.regularMarketPrice
            
            # Calculate moving averages
            $sma20 = 'N/A'
            $sma50 = 'N/A'
            $sma100 = 'N/A'
            
            if ($closes.Count -ge 20) {
                $sma20 = [math]::Round(($closes[-20..-1] | Measure-Object -Average).Average, 2)
            }
            if ($closes.Count -ge 50) {
                $sma50 = [math]::Round(($closes[-50..-1] | Measure-Object -Average).Average, 2)
            }
            if ($closes.Count -ge 100) {
                $sma100 = [math]::Round(($closes[-100..-1] | Measure-Object -Average).Average, 2)
            }
            
            # Generate simple recommendation based on moving averages
            $trend = 'neutral'
            $recommendation = 'hold'
            
            if ($sma20 -ne 'N/A' -and $sma50 -ne 'N/A') {
                if ($currentPrice -gt $sma20 -and $sma20 -gt $sma50) {
                    $trend = 'bullish'
                    $recommendation = 'buy'
                }
                elseif ($currentPrice -lt $sma20 -and $sma20 -lt $sma50) {
                    $trend = 'bearish'
                    $recommendation = 'sell'
                }
            }
            
            # Calculate momentum (rate of change)
            $momentum5d = 'N/A'
            $momentum20d = 'N/A'
            
            if ($closes.Count -ge 5 -and $closes[-5] -gt 0) {
                $momentum5d = [math]::Round((($closes[-1] - $closes[-5]) / $closes[-5]) * 100, 2)
            }
            if ($closes.Count -ge 20 -and $closes[-20] -gt 0) {
                $momentum20d = [math]::Round((($closes[-1] - $closes[-20]) / $closes[-20]) * 100, 2)
            }
            
            $recommendations = [ordered]@{
                symbol              = $Symbol
                companyName         = $meta.longName
                currentPrice        = $currentPrice
                currency            = $meta.currency
                
                # Moving averages
                sma20               = $sma20
                sma50               = $sma50
                sma100              = $sma100
                
                # Position relative to MAs
                aboveSMA20          = if ($sma20 -ne 'N/A') { $currentPrice -gt $sma20 } else { 'N/A' }
                aboveSMA50          = if ($sma50 -ne 'N/A') { $currentPrice -gt $sma50 } else { 'N/A' }
                aboveSMA100         = if ($sma100 -ne 'N/A') { $currentPrice -gt $sma100 } else { 'N/A' }
                
                # Momentum
                momentum5Day        = $momentum5d
                momentum20Day       = $momentum20d
                
                # Overall analysis
                trend               = $trend
                technicalSignal     = $recommendation
                
                # 52-week context
                fiftyTwoWeekHigh    = $meta.fiftyTwoWeekHigh
                fiftyTwoWeekLow     = $meta.fiftyTwoWeekLow
                pctFrom52WeekHigh   = if ($meta.fiftyTwoWeekHigh -gt 0) {
                    [math]::Round((($currentPrice - $meta.fiftyTwoWeekHigh) / $meta.fiftyTwoWeekHigh) * 100, 2)
                } else { 'N/A' }
            }
            
            if ($AsObject) {
                return [PSCustomObject]$recommendations
            }
            
            return $recommendations | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching price analysis for $Symbol`: $_"
        }
    }
}

function Get-CompanyNews {
    <#
    .SYNOPSIS
        Gets company news and press releases for a given stock symbol

    .DESCRIPTION
        Use this function to get company news and press releases for a given stock symbol.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER NumStories
        The number of news stories to return. Defaults to 3.

    .PARAMETER AsObject
        If specified, returns the data as PowerShell objects instead of JSON

    .EXAMPLE
        Get-CompanyNews -Symbol 'AAPL'
        Returns the 3 most recent news stories for Apple Inc.

    .EXAMPLE
        Get-CompanyNews -Symbol 'NVDA' -NumStories 10
        Returns the 10 most recent news stories for NVIDIA
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [int]$NumStories = 3,
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching company news for $Symbol"
            
            $searchResult = Get-YahooFinanceSearch -Query $Symbol -NewsCount $NumStories
            
            $news = @()
            foreach ($item in $searchResult.news | Select-Object -First $NumStories) {
                $publishTime = $null
                if ($item.providerPublishTime) {
                    $publishTime = [DateTimeOffset]::FromUnixTimeSeconds($item.providerPublishTime).DateTime.ToString('yyyy-MM-dd HH:mm:ss')
                }
                
                $newsItem = [ordered]@{
                    title         = $item.title
                    publisher     = $item.publisher
                    link          = $item.link
                    providerPublishTime = $publishTime
                    type          = $item.type
                    relatedTickers = $item.relatedTickers
                }
                $news += $newsItem
            }
            
            if ($AsObject) {
                return $news | ForEach-Object { [PSCustomObject]$_ }
            }
            
            return $news | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching company news for $Symbol`: $_"
        }
    }
}

function Get-TechnicalIndicators {
    <#
    .SYNOPSIS
        Gets technical indicators for a given stock symbol

    .DESCRIPTION
        Use this function to get technical indicators for a given stock symbol.
        Returns historical OHLCV data that can be used for technical analysis.

    .PARAMETER Symbol
        The stock symbol (e.g., 'AAPL', 'MSFT', 'NVDA')

    .PARAMETER Period
        The time period for which to retrieve technical indicators.
        Valid periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max. Defaults to 3mo.

    .PARAMETER AsObject
        If specified, returns the data as PowerShell objects instead of JSON

    .EXAMPLE
        Get-TechnicalIndicators -Symbol 'AAPL'
        Returns 3 months of technical indicator data for Apple Inc.

    .EXAMPLE
        Get-TechnicalIndicators -Symbol 'NVDA' -Period '1y' -AsObject
        Returns 1 year of data for NVIDIA as PowerShell objects
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Symbol,
        
        [Parameter()]
        [ValidateSet('1d', '5d', '1mo', '3mo', '6mo', '1y', '2y', '5y', '10y', 'ytd', 'max')]
        [string]$Period = '3mo',
        
        [Parameter()]
        [switch]$AsObject
    )
    
    process {
        try {
            Write-Verbose "Fetching technical indicators for $Symbol"
            
            $response = Invoke-YahooFinanceV8Request -Symbol $Symbol -Range $Period -Interval '1d'
            
            $chart = $response.chart.result[0]
            $timestamps = $chart.timestamp
            $quote = $chart.indicators.quote[0]
            $adjCloseData = $chart.indicators.adjclose
            $adjClose = $null
            if ($adjCloseData -and $adjCloseData[0]) {
                $adjClose = $adjCloseData[0].adjclose
            }
            
            $indicators = @{}
            
            for ($i = 0; $i -lt $timestamps.Count; $i++) {
                $timestamp = $timestamps[$i]
                $date = [DateTimeOffset]::FromUnixTimeSeconds($timestamp).DateTime.ToString('yyyy-MM-dd HH:mm:ss')
                
                $adjCloseValue = $null
                if ($adjClose) {
                    $adjCloseValue = $adjClose[$i]
                }
                
                $indicators[$date] = [ordered]@{
                    Open      = $quote.open[$i]
                    High      = $quote.high[$i]
                    Low       = $quote.low[$i]
                    Close     = $quote.close[$i]
                    Volume    = $quote.volume[$i]
                    'Adj Close' = $adjCloseValue
                }
            }
            
            if ($AsObject) {
                $result = @()
                foreach ($key in $indicators.Keys | Sort-Object) {
                    $result += [PSCustomObject]@{
                        Date      = $key
                        Open      = $indicators[$key].Open
                        High      = $indicators[$key].High
                        Low       = $indicators[$key].Low
                        Close     = $indicators[$key].Close
                        Volume    = $indicators[$key].Volume
                        'Adj Close' = $indicators[$key]['Adj Close']
                    }
                }
                return $result
            }
            
            return $indicators | ConvertTo-Json -Depth 10
        }
        catch {
            return "Error fetching technical indicators for $Symbol`: $_"
        }
    }
}

#endregion

#region Aliases

Set-Alias -Name Get-StockPrice -Value Get-CurrentStockPrice
Set-Alias -Name Get-Quote -Value Get-CurrentStockPrice
Set-Alias -Name Get-Fundamentals -Value Get-StockFundamentals
Set-Alias -Name Get-Financials -Value Get-IncomeStatements
Set-Alias -Name Get-News -Value Get-CompanyNews
Set-Alias -Name Get-Recommendations -Value Get-AnalystRecommendations

#endregion

# # Export module members
# Export-ModuleMember -Function @(
#     'Get-CurrentStockPrice',
#     'Get-CompanyInfo',
#     'Get-HistoricalStockPrices',
#     'Get-StockFundamentals',
#     'Get-IncomeStatements',
#     'Get-KeyFinancialRatios',
#     'Get-AnalystRecommendations',
#     'Get-CompanyNews',
#     'Get-TechnicalIndicators'
# ) -Alias @(
#     'Get-StockPrice',
#     'Get-Quote',
#     'Get-Fundamentals',
#     'Get-Financials',
#     'Get-News',
#     'Get-Recommendations'
# )
