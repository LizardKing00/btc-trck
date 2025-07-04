#!/bin/bash
# btc-trck installer with man page support

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="btc-trck"

# Check if running as root for system install
if [[ $EUID -eq 0 ]]; then
    echo "Installing btc-trck system-wide..."
    INSTALL_DIR="/usr/local/bin"
    MAN_DIR="/usr/local/man/man1"
else
    echo "Installing btc-trck for current user..."
    INSTALL_DIR="$HOME/.local/bin"
    MAN_DIR="$HOME/.local/share/man/man1"
    mkdir -p "$INSTALL_DIR" "$MAN_DIR"
fi

# Check dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Please install them first:"
        echo "  Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "  macOS: brew install ${missing[*]}"
        echo "  CentOS/RHEL: sudo yum install ${missing[*]}"
        exit 1
    fi
}

# Create man page
create_man_page() {
    local man_file="$MAN_DIR/btc-trck.1"
    
    echo "Creating man page at $man_file..."
    mkdir -p "$MAN_DIR"
    
    cat > "$man_file" << 'EOF'
.TH BTC-TRCK 1 "2025" "btc-trck" "User Commands"
.SH NAME
btc-trck \- Bitcoin price tracker with ASCII charts
.SH SYNOPSIS
.B btc-trck
[\fIOPTIONS\fR]
.SH DESCRIPTION
.B btc-trck
is a command-line Bitcoin price tracker that displays current Bitcoin prices in various currencies with optional ASCII charts. It supports multiple cryptocurrency APIs with automatic fallback for maximum reliability.

The tool stores configuration in a user-specific config file and supports API keys for higher rate limits. Historical price charts are generated using ASCII art for terminal-friendly visualization.

.SH OPTIONS
.TP
.B \-\-plot
Show price chart for the last 30 days using ASCII art
.TP
.B \-\-config
Show current configuration settings
.TP
.B \-\-config.api \fIAPI\fR
Set preferred API. Valid values: \fBcoindesk\fR, \fBbinance\fR, \fBcoingecko\fR, or empty string for automatic fallback
.TP
.B \-\-config.currency \fICURRENCY\fR
Set currency code (must be quoted). Examples: "EUR", "USD", "GBP", "JPY"
.TP
.B \-\-config.coingecko \fIKEY\fR
Set CoinGecko API key for higher rate limits
.TP
.B \-\-config.binance \fIKEY\fR
Set Binance API key for higher rate limits
.TP
.B \-\-help, \-h
Show brief help message

.SH SUPPORTED APIS
.TP
.B coindesk
CoinDesk API - Most reliable, supports major currencies
.TP
.B binance
Binance API - High uptime, requires exact currency pairs
.TP
.B coingecko
CoinGecko API - Most comprehensive, supports historical data
.TP
.B "" (empty)
Automatic fallback through all APIs (default)

.SH SUPPORTED CURRENCIES
EUR, USD, GBP, JPY, CAD, AUD, CHF, CNY, and many others. Note that not all APIs support all currencies. The script will automatically fallback to working APIs for your selected currency.

.SH ENVIRONMENT VARIABLES
.TP
.B DEBUG=1
Enable debug output for troubleshooting API calls and data parsing

.SH EXAMPLES
.TP
Basic usage:
.nf
.B btc-trck
Show current Bitcoin price in default currency
.fi
.TP
.nf
.B btc-trck --plot
Show current price with 30-day ASCII chart
.fi
.TP
Configuration:
.nf
.B btc-trck --config
Show current settings
.fi
.TP
.nf
.B btc-trck --config.currency "USD"
Set currency to US Dollar
.fi
.TP
.nf
.B btc-trck --config.api coindesk
Set preferred API to CoinDesk
.fi
.TP
.nf
.B btc-trck --config.api ""
Use automatic API fallback
.fi
.TP
API keys (for higher rate limits):
.nf
.B btc-trck --config.coingecko "your-key"
Set CoinGecko API key
.fi
.TP
.nf
.B btc-trck --config.binance "your-key"
Set Binance API key
.fi
.TP
Troubleshooting:
.nf
.B DEBUG=1 btc-trck
Show debug information
.fi
.TP
.nf
.B DEBUG=1 btc-trck --plot
Debug with chart plotting
.fi

.SH FILES
.TP
.B $XDG_CONFIG_HOME/btc-trck/config
.TQ
.B $HOME/.config/btc-trck/config
Configuration file containing API preferences, currency settings, and API keys. Created automatically on first run.

.SH CONFIGURATION FORMAT
The configuration file uses shell variable format:
.nf
.B API="coindesk"
.B CURRENCY="EUR"
.B COINGECKO_KEY="your-api-key"
.B BINANCE_KEY="your-api-key"
.fi

.SH NOTES
.IP \[bu] 2
Script automatically creates config file on first run
.IP \[bu] 2
Uses multiple API fallbacks for maximum reliability
.IP \[bu] 2
Historical charts require CoinGecko API and may be rate-limited
.IP \[bu] 2
Currency values must be quoted when setting via command line
.IP \[bu] 2
API keys are optional but help avoid rate limiting
.IP \[bu] 2
Charts use colored output: green for prices above 30-day average, red for below

.SH DEPENDENCIES
.TP
.B curl
Required for API calls
.TP
.B jq
Required for JSON parsing

.SH EXIT STATUS
.TP
.B 0
Success
.TP
.B 1
Error (missing dependencies, API failures, invalid arguments)

.SH AUTHOR
btc-trck Bitcoin price tracker

.SH REPORTING BUGS
Enable debug mode with DEBUG=1 for troubleshooting API issues.

.SH SEE ALSO
.BR curl (1),
.BR jq (1)
EOF

    # Update man database if possible
    if command -v mandb &> /dev/null && [[ $EUID -eq 0 ]]; then
        echo "Updating man database..."
        mandb -q 2>/dev/null || true
    elif command -v makewhatis &> /dev/null && [[ $EUID -eq 0 ]]; then
        echo "Updating man database..."
        makewhatis /usr/local/man 2>/dev/null || true
    fi
    
    echo "Man page created successfully!"
}

# Install function
install_btc_trck() {
    echo "Checking dependencies..."
    check_dependencies
    
    echo "Installing btc-trck to $INSTALL_DIR..."
    cp btc-trck "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/btc-trck"
    
    # Create man page
    create_man_page
    
    echo "btc-trck installed successfully!"
    echo "Run 'btc-trck --help' for quick help or 'man btc-trck' for full documentation."
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        echo "Note: Add $INSTALL_DIR to your PATH:"
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
    
    # Add to MANPATH if needed (user install)
    if [[ $EUID -ne 0 && ":${MANPATH:-}:" != *":$HOME/.local/share/man:"* ]]; then
        echo ""
        echo "Note: Add to MANPATH for user man pages:"
        echo "  echo 'export MANPATH=\"\$HOME/.local/share/man:\$MANPATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
}

install_btc_trck
