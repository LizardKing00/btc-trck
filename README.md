# btc-trck 🚀₿

**Bitcoin price tracker with terminal charts - Because checking prices every 5 minutes is totally normal.**

Track Bitcoin prices and 30-day charts right in your terminal. Multiple currencies, multiple APIs, color-coded charts. No GUI needed - just pure terminal Bitcoin addiction.

## Features

- 🔥 **Real-time prices** in EUR, USD, GBP, JPY, and more
- 📊 **ASCII charts** showing 30-day price history  
- 🎨 **Color-coded** - green above average, red below average
- 🔄 **Multiple APIs** with auto-fallback (CoinDesk, Binance, CoinGecko)
- ⚙️ **Configurable** - set your preferred currency and API
- 🔑 **API key support** for higher rate limits

## Installation

### Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/btc-trck/main/install.sh | bash
```

### Manual Install
```bash
git clone https://github.com/yourusername/btc-trck.git
cd btc-trck
bash install.sh
```

### Dependencies
- `curl` and `jq` (installer checks and guides you)

## Usage

```bash
# Current price
btc-trck

# Price with 30-day chart
btc-trck --plot

# Configuration
btc-trck --config
btc-trck --config.currency "USD"
btc-trck --config.api coindesk
```

## Example Output

```
Current Bitcoin Price
€92841.78
Data from Binance

Bitcoin Price Chart (Last 30 Days)
Price Range: €87681 - €96513
30 days average: €91647.18
Historical data from CoinGecko
€ 96513            ****                                             
€ 96071            ||||                                             
€ 95630            ||||                                             
€ 95188            ||||                                             
€ 94747            ||||                                             
€ 94305            ||||**                                           
€ 93863            ||||||                                           
€ 93422            ||||||                                           
€ 92980            ||||||                                          *
€ 92539 *      ****||||||        **                        **      |
€ 92097 |      ||||||||||        ||                        ||    **|
€ 91655 |**  **||||||||||  **    ||                ****  **||    |||
€ 91214 |||  ||||||||||||**||****||****          **||||**||||    |||
€ 90772 |||  ||||||||||||||||||||||||||**      **||||||||||||**  |||
€ 90331 |||  ||||||||||||||||||||||||||||      ||||||||||||||||  |||
€ 89889 |||  ||||||||||||||||||||||||||||      ||||||||||||||||  |||
€ 89447 |||  ||||||||||||||||||||||||||||**    ||||||||||||||||**|||
€ 89006 |||  ||||||||||||||||||||||||||||||    |||||||||||||||||||||
€ 88564 |||**||||||||||||||||||||||||||||||    |||||||||||||||||||||
€ 88123 |||||||||||||||||||||||||||||||||||**  |||||||||||||||||||||
€ 87681 |||||||||||||||||||||||||||||||||||||**|||||||||||||||||||||
        |         |         |         |         |         |         
        30d       25d       20d       15d       10d       5d        
        Days ago
```

## Configuration

Settings stored in `~/.config/btc-trck/config`:

- **Currency**: EUR, USD, GBP, JPY, etc.
- **API**: coindesk, binance, coingecko, or auto-fallback
- **API Keys**: Optional, for higher rate limits

## Troubleshooting

```bash
# Debug mode
DEBUG=1 btc-trck

# Common issues
sudo apt install curl jq  # Ubuntu/Debian
brew install curl jq      # macOS
```

## License

MIT License - Track responsibly.

---

**🌙 To the moon! HODL! 🚀₿**

*Not financial advice. Just a terminal app for Bitcoin degenerates.*
