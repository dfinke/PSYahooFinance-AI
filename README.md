# PSYahooFinance-AI

A PowerShell port of the Python [agno YFinanceTools](https://github.com/agno-agi/agno/blob/main/libs/agno/agno/tools/yfinance.py) toolkit for getting financial data from Yahoo Finance.

## Features

- **Get-CurrentStockPrice**: Get the current stock price for a given symbol
- **Get-CompanyInfo**: Get company information and overview
- **Get-HistoricalStockPrices**: Get historical OHLCV data
- **Get-StockFundamentals**: Get fundamental financial data (52-week range, price metrics)
- **Get-IncomeStatements**: Get yearly performance data and returns
- **Get-KeyFinancialRatios**: Get calculated financial metrics (volatility, YTD returns)
- **Get-AnalystRecommendations**: Get technical analysis with moving averages and trend signals
- **Get-CompanyNews**: Get recent company news
- **Get-TechnicalIndicators**: Get technical indicator data (OHLCV with adjusted close)

## Installation

```powershell
# Install from PowerShell Gallery
Install-Module -Name PSYahooFinance-AI

# Then import the module:
Import-Module .\PSYahooFinance-AI.psd1
```

## Usage Examples

### Get Current Stock Price

```powershell
Get-CurrentStockPrice -Symbol 'AAPL'
# Output: 175.4300

# Using alias
Get-StockPrice -Symbol 'NVDA'

# Pipeline support
'AAPL', 'MSFT', 'GOOGL' | Get-CurrentStockPrice
```

### Get Company Information

```powershell
# Returns JSON by default
Get-CompanyInfo -Symbol 'AAPL'

# Returns PowerShell object
$company = Get-CompanyInfo -Symbol 'AAPL' -AsObject
$company.Name              # NVIDIA Corporation
$company.Symbol            # NVDA
$company.'52 Week High'    # 212.19
$company.'52 Week Low'     # 86.62
```

### Get Historical Stock Prices

```powershell
# Get 1 month of daily data (default)
Get-HistoricalStockPrices -Symbol 'AAPL'

# Get 3 months of weekly data
Get-HistoricalStockPrices -Symbol 'AAPL' -Period '3mo' -Interval '1wk'

# As PowerShell objects for easy manipulation
$history = Get-HistoricalStockPrices -Symbol 'NVDA' -Period '1y' -AsObject
$history | Select-Object Date, Close | Format-Table
```

**Valid Periods**: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max

**Valid Intervals**: 1d, 5d, 1wk, 1mo, 3mo

### Get Stock Fundamentals

```powershell
$fundamentals = Get-StockFundamentals -Symbol 'TSLA' -AsObject
$fundamentals.current_price
$fundamentals.'52_week_high'
$fundamentals.'52_week_low'
$fundamentals.pct_from_52wk_high  # Percentage from 52-week high
```

### Get Yearly Performance

```powershell
$yearly = Get-IncomeStatements -Symbol 'MSFT' -AsObject
$yearly | Select-Object Year, 'Year Open', 'Year Close', 'Year Return %' | Format-Table
```

### Get Key Financial Metrics

```powershell
$ratios = Get-KeyFinancialRatios -Symbol 'GOOGL' -AsObject
$ratios.regularMarketPrice       # Current price
$ratios.ytdReturnPct             # Year-to-date return
$ratios.annualizedVolatilityPct  # Annualized volatility
$ratios.dayChangePct             # Day change percentage
```

### Get Technical Analysis

```powershell
$analysis = Get-AnalystRecommendations -Symbol 'NVDA' -AsObject
$analysis.trend              # bullish, bearish, or neutral
$analysis.technicalSignal    # buy, sell, or hold
$analysis.sma20              # 20-day simple moving average
$analysis.sma50              # 50-day simple moving average
$analysis.momentum5Day       # 5-day momentum percentage
$analysis.momentum20Day      # 20-day momentum percentage
```

### Get Company News

```powershell
# Get 3 recent news stories (default)
Get-CompanyNews -Symbol 'AAPL'

# Get 10 news stories as objects
$news = Get-CompanyNews -Symbol 'TSLA' -NumStories 10 -AsObject
$news | Select-Object title, publisher, providerPublishTime
```

### Get Technical Indicators

```powershell
# Get 3 months of data (default)
Get-TechnicalIndicators -Symbol 'AAPL'

# Get 1 year of data as objects
$indicators = Get-TechnicalIndicators -Symbol 'SPY' -Period '1y' -AsObject
$indicators | Select-Object Date, Close, Volume
```

## Aliases

The module provides convenient aliases:

| Alias | Function |
|-------|----------|
| `Get-StockPrice` | `Get-CurrentStockPrice` |
| `Get-Quote` | `Get-CurrentStockPrice` |
| `Get-Fundamentals` | `Get-StockFundamentals` |
| `Get-Financials` | `Get-IncomeStatements` |
| `Get-News` | `Get-CompanyNews` |
| `Get-Recommendations` | `Get-AnalystRecommendations` |

## Output Formats

All functions support two output formats:

1. **JSON (default)**: Returns a JSON string for compatibility with other tools
2. **PowerShell Object**: Use the `-AsObject` switch to get a PowerShell object for easier manipulation

## Requirements

- PowerShell 5.1 or later
- Internet connection (uses Yahoo Finance API)

## API Notes

This module uses the Yahoo Finance v8 chart API which provides:
- Real-time and historical price data
- Company metadata (name, exchange, currency)
- 52-week high/low prices
- Volume data

Some features from the original Python yfinance library (like detailed financial statements, analyst recommendations from brokers, P/E ratios, etc.) require authenticated API access that Yahoo Finance has restricted. This module provides technical analysis alternatives using available price data.

## AI-Assisted Development

This PowerShell port was done using AI only.

- **Tools**: VS Code, Claude Opus 4.5 (Preview)
- **Prompt**: "Implement the python YFinanceTools in PowerShell"

The agent implemented and then tested the code via CLI calls. Uncovered issues like initially using PS 7.x only constructs. It then updated the code to work with PS 5.1.

Other cases were detected and fixed.

**Elapsed time**: ~15 min

## License

This project is provided as-is for educational and personal use.

## Acknowledgments

- Original Python implementation: [agno YFinanceTools](https://github.com/agno-agi/agno)
- Data provided by: [Yahoo Finance](https://finance.yahoo.com)
