# btc-trck - Bitcoin Price Tracker

A powerful and reliable command-line Bitcoin price tracker that displays current prices and historical charts directly in your terminal.

## Features

- **Real-time Bitcoin prices** in multiple currencies (EUR, USD, GBP, JPY, and more)
- **ASCII terminal charts** showing 30-day price history
- **Multiple API support** with automatic fallback for maximum reliability
- **Color-coded charts** - green for above average, red for below average prices
- **Configurable settings** with persistent configuration file
- **API key support** for higher rate limits
- **Debug mode** for troubleshooting

## Installation

### Prerequisites

- `bash` (version 4.0 or higher)
- `curl` for API requests
- `jq` for JSON parsing

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install curl jq
```

#### macOS
```bash
brew install curl jq
```

#### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL
sudo yum install curl jq

# Fedora
sudo dnf install curl jq
```

### Install btc-trck

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/your-repo/btc-trck/main/btc-trck
```

2. Make it executable:
```bash
chmod +x btc-trck
```

3. Move to your PATH (optional):
```bash
sudo mv btc-trck /usr/local/bin/
```

## Quick Start

```bash
# Show current Bitcoin price
./btc-trck

# Show price with 30-day chart
./btc-trck --plot

# Show current configuration
./btc-trck --config
```

## Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `btc-trck` | Display current Bitcoin price |
| `btc-trck --plot` | Display price with 30-day chart |
| `btc-trck --config` | Show current configuration |
| `btc-trck --help` | Show help information |

### Configuration Commands

| Command | Description |
|---------|-------------|
| `btc-trck --config.api <api>` | Set preferred API |
| `btc-trck --config.currency "<currency>"` | Set currency (quoted) |
| `btc-trck --config.coingecko "<key>"` | Set CoinGecko API key |
| `btc-trck --config.binance "<key>"` | Set Binance API key |

## Configuration

The script uses a configuration file located at `~/.config/btc-trck/config`. This file is automatically created with default settings on first run.

### Configuration Options

- **API**: Preferred API to use (`coindesk`, `binance`, `coingecko`, or empty for automatic)
- **CURRENCY**: Currency code (e.g., "EUR", "USD", "GBP", "JPY")
- **COINGECKO_KEY**: CoinGecko API key (optional)
- **BINANCE_KEY**: Binance API key (optional)

### Example Configuration

```bash
# Set currency to US Dollar
btc-trck --config.currency "USD"

# Set preferred API to CoinDesk
btc-trck --config.api coindesk

# Add CoinGecko API key for higher rate limits
btc-trck --config.coingecko "your-api-key-here"

# Use automatic API fallback
btc-trck --config.api ""
```

## Supported APIs

### Primary APIs

1. **CoinDesk** (`coindesk`)
   - Most reliable and stable
   - Limited currency support
   - No API key required

2. **Binance** (`binance`)
   - High uptime and fast
   - Good currency support
   - Optional API key for higher limits

3. **CoinGecko** (`coingecko`)
   - Comprehensive data
   - Required for historical charts
   - Optional API key for higher limits

### API Fallback System

The script automatically tries APIs in this order:
1. Your configured preferred API (if set)
2. CoinDesk (most reliable)
3. Binance (high uptime)
4. CoinGecko (comprehensive)

## Supported Currencies

| Currency | Code | Symbol |
|----------|------|--------|
| Euro | EUR | € |
| US Dollar | USD | $ |
| British Pound | GBP | £ |
| Japanese Yen | JPY | ¥ |
| Canadian Dollar | CAD | CAD |
| Australian Dollar | AUD | AUD |
| Swiss Franc | CHF | CHF |
| Chinese Yuan | CNY | CNY |

*Note: Not all APIs support all currencies. The script will automatically fallback to supported APIs.*

## Examples

### Basic Usage
```bash
# Simple price check
$ btc-trck
Current Bitcoin Price
$43,250.75
Data from CoinDesk

# Price with chart
$ btc-trck --plot
Current Bitcoin Price
$43,250.75
Data from CoinDesk

Bitcoin Price Chart (Last 30 Days)
Price Range: $41,200 - $45,800
Average Price: $43,127.50
Historical data from CoinGecko
Green: Above average | Red: Below average

$45800  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
$45400  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
[... chart continues ...]
```

### Configuration Examples
```bash
# Check current settings
$ btc-trck --config
Current Configuration
Config file: /home/user/.config/btc-trck/config

API: coindesk
CURRENCY: USD
COINGECKO_KEY: ***set***
BINANCE_KEY: 

# Change to British Pounds
$ btc-trck --config.currency "GBP"
Updated CURRENCY="GBP" in config file

# Set CoinGecko API key
$ btc-trck --config.coingecko "your-api-key-here"
Updated COINGECKO_KEY="your-api-key-here" in config file
```

### Advanced Usage
```bash
# Debug mode for troubleshooting
$ DEBUG=1 btc-trck
DEBUG: Trying CoinDesk API...
DEBUG: CoinDesk response: {"bpi":{"USD":{"rate_float":43250.75}}}
DEBUG: CoinDesk price: 43250.75
Current Bitcoin Price
$43,250.75
Data from CoinDesk

# Force specific API
$ btc-trck --config.api binance
Updated API="binance" in config file
```

## Chart Color Coding

The 30-day price chart uses color coding to show price trends:

- **🟢 Green columns**: Price above 30-day average
- **🔴 Red columns**: Price below 30-day average

This gives you instant visual feedback on whether Bitcoin was performing above or below its recent average.

## Troubleshooting

### Common Issues

1. **"curl: command not found"**
   ```bash
   # Install curl
   sudo apt install curl  # Ubuntu/Debian
   brew install curl      # macOS
   ```

2. **"jq: command not found"**
   ```bash
   # Install jq
   sudo apt install jq    # Ubuntu/Debian
   brew install jq        # macOS
   ```

3. **"Invalid price data received"**
   ```bash
   # Enable debug mode to see what's happening
   DEBUG=1 btc-trck
   
   # Try different API
   btc-trck --config.api binance
   ```

4. **Rate limiting errors**
   ```bash
   # Add API keys for higher limits
   btc-trck --config.coingecko "your-api-key"
   btc-trck --config.binance "your-api-key"
   ```

### Debug Mode

Enable debug mode to see detailed information about API requests:

```bash
DEBUG=1 btc-trck
DEBUG=1 btc-trck --plot
```

This will show:
- Which APIs are being tried
- API responses
- Error messages
- Processing steps

## API Keys

### Getting API Keys

1. **CoinGecko**: Sign up at [coingecko.com](https://www.coingecko.com/en/api)
2. **Binance**: Sign up at [binance.com](https://www.binance.com/en/binance-api)

### Why Use API Keys?

- **Higher rate limits**: Avoid being blocked during heavy usage
- **Better reliability**: Priority access to API endpoints
- **Additional features**: Some APIs offer premium data with keys

## File Locations

- **Configuration**: `~/.config/btc-trck/config`
- **Script**: Wherever you installed `btc-trck`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

The Unlicence - see LICENSE file for details.

## Support

- **Issues**: Report bugs and request features on GitHub
- **Debug**: Use `DEBUG=1` for troubleshooting
- **Help**: Run `btc-trck --help` for usage information

## Changelog

### Version 1.0.0
- Initial release
- Multi-API support with fallback
- Configurable currency and API preferences
- ASCII terminal charts
- Color-coded price visualization
- API key support
- Debug mode

---

**Diamond hands, to the moon!** 🚀₿
