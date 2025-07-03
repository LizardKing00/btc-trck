#!/bin/bash

# btc-trck - Bitcoin price tracker in EUR
# Usage: btc-trck [--plot]

set -euo pipefail



# Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/btc-trck"
CONFIG_FILE="$CONFIG_DIR/config"

# Default configuration values
DEFAULT_API=""
DEFAULT_CURRENCY="EUR"
DEFAULT_COINGECKO_KEY=""
DEFAULT_BINANCE_KEY=""

# Initialize config variables with defaults
API="$DEFAULT_API"
CURRENCY="$DEFAULT_CURRENCY"
COINGECKO_KEY="$DEFAULT_COINGECKO_KEY"
BINANCE_KEY="$DEFAULT_BINANCE_KEY"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if required tools are available
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required but not installed." >&2
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed." >&2
        echo "Install with: sudo apt install jq (Ubuntu/Debian) or brew install jq (macOS)" >&2
        exit 1
    fi
}

# Function to create default config file
create_default_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# btc-trck configuration file
# Available APIs: coindesk, binance, coingecko
# Leave API empty to use automatic fallback
API="${DEFAULT_API}"

# Currency code (EUR, USD, GBP, etc.)
CURRENCY="${DEFAULT_CURRENCY}"

# API Keys (leave empty if not needed)
COINGECKO_KEY="${DEFAULT_COINGECKO_KEY}"
BINANCE_KEY="${DEFAULT_BINANCE_KEY}"
EOF
    echo "Created default config file at: $CONFIG_FILE"
}

# Function to load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Source the config file safely by temporarily disabling unbound variable checking
    set +u
    source "$CONFIG_FILE" 2>/dev/null || true
    set -u
    
    # Ensure all variables are properly set with defaults if missing or empty
    API="${API:-${DEFAULT_API}}"
    CURRENCY="${CURRENCY:-${DEFAULT_CURRENCY}}"
    COINGECKO_KEY="${COINGECKO_KEY:-${DEFAULT_COINGECKO_KEY}}"
    BINANCE_KEY="${BINANCE_KEY:-${DEFAULT_BINANCE_KEY}}"
    
    # Ensure CURRENCY is always uppercase string
    CURRENCY=$(echo "${CURRENCY}" | tr '[:lower:]' '[:upper:]')
}

# Function to update config value
update_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Validate key
    case "$key" in
        API|CURRENCY|COINGECKO_KEY|BINANCE_KEY)
            ;;
        *)
            echo "Error: Invalid config key '$key'" >&2
            echo "Valid keys: API, CURRENCY, COINGECKO_KEY, BINANCE_KEY" >&2
            exit 1
            ;;
    esac
    
    # Ensure CURRENCY is always uppercase
    if [[ "$key" == "CURRENCY" ]]; then
        value=$(echo "$value" | tr '[:lower:]' '[:upper:]')
    fi
    
    # Update the config file with proper quoting
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=\"${value}\"/" "$CONFIG_FILE"
    else
        echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
    fi
    
    echo "Updated ${key}=\"${value}\" in config file"
}

# Function to show current configuration
show_config() {
    load_config
    echo -e "\n${BLUE}Current Configuration${NC}"
    echo -e "${YELLOW}Config file: $CONFIG_FILE${NC}\n"
    echo "API: ${API:-automatic fallback}"
    echo "CURRENCY: $CURRENCY"
    echo "COINGECKO_KEY: ${COINGECKO_KEY:+***set***}"
    echo "BINANCE_KEY: ${BINANCE_KEY:+***set***}"
    echo ""
}

# Function to get API endpoints based on currency
get_api_endpoints() {
    local currency="$1"
    local currency_lower
    currency_lower=$(echo "$currency" | tr '[:upper:]' '[:lower:]')
    
    COINDESK_API="https://api.coindesk.com/v1/bpi/currentprice/${currency}.json"
    BINANCE_API="https://api.binance.com/api/v3/ticker/price?symbol=BTC${currency}"
    COINGECKO_CURRENT="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currency_lower}"
    COINGECKO_HISTORICAL="https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=${currency_lower}&days=30&interval=daily"
}

# Function to debug output
debug_log() {
    local debug_value="${DEBUG:-0}"
    if [[ "$debug_value" -eq 1 ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Function to get current Bitcoin price with multiple API fallbacks
# Returns: "price|source"
get_current_price() {
    local price=""
    local source=""
    local response=""
    
    # Load config and set up API endpoints
    load_config
    get_api_endpoints "$CURRENCY"
    
    # If specific API is configured, try it first
    if [[ -n "$API" ]]; then
        case "$API" in
            coindesk)
                if try_coindesk_api; then return 0; fi
                ;;
            binance)
                if try_binance_api; then return 0; fi
                ;;
            coingecko)
                if try_coingecko_api; then return 0; fi
                ;;
            *)
                echo "Warning: Unknown API '$API' in config, using fallback" >&2
                ;;
        esac
    fi
    
    # Fallback to trying all APIs in order
    if try_coindesk_api; then return 0; fi
    if try_binance_api; then return 0; fi
    if try_coingecko_api; then return 0; fi
    
    # If all APIs failed
    echo "Error: All price APIs failed or returned invalid data" >&2
    echo "Try running with DEBUG=1 ./btc-trck for more information" >&2
    exit 1
}

# Function to try CoinDesk API
try_coindesk_api() {
    debug_log "Trying CoinDesk API..."
    local response
    response=$(curl -s -m 10 "$COINDESK_API" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        debug_log "CoinDesk response: $response"
        local price
        price=$(echo "$response" | jq -r ".bpi.${CURRENCY}.rate_float // empty" 2>/dev/null)
        if [[ -n "$price" && "$price" != "null" ]]; then
            debug_log "CoinDesk price: $price"
            printf "%.2f|CoinDesk" "$price"
            return 0
        fi
    fi
    return 1
}

# Function to try Binance API
try_binance_api() {
    debug_log "Trying Binance API..."
    local response
    local url="$BINANCE_API"
    
    # Add API key if configured
    if [[ -n "$BINANCE_KEY" ]]; then
        url="${url}&apikey=${BINANCE_KEY}"
    fi
    
    response=$(curl -s -m 10 "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        debug_log "Binance response: $response"
        local price
        price=$(echo "$response" | jq -r '.price // empty' 2>/dev/null)
        if [[ -n "$price" && "$price" != "null" ]]; then
            debug_log "Binance price: $price"
            printf "%.2f|Binance" "$price"
            return 0
        fi
    fi
    return 1
}

# Function to try CoinGecko API
try_coingecko_api() {
    debug_log "Trying CoinGecko API..."
    local response
    local url="$COINGECKO_CURRENT"
    
    # Add API key if configured
    if [[ -n "$COINGECKO_KEY" ]]; then
        url="${url}&x_cg_api_key=${COINGECKO_KEY}"
    fi
    
    response=$(curl -s -m 10 "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        debug_log "CoinGecko response: $response"
        local currency_lower
        currency_lower=$(echo "$CURRENCY" | tr '[:upper:]' '[:lower:]')
        local price
        price=$(echo "$response" | jq -r ".bitcoin.${currency_lower} // empty" 2>/dev/null)
        if [[ -n "$price" && "$price" != "null" ]]; then
            debug_log "CoinGecko price: $price"
            printf "%.2f|CoinGecko" "$price"
            return 0
        fi
    fi
    return 1
}

# Function to get historical price data
get_historical_data() {
    load_config
    get_api_endpoints "$CURRENCY"
    
    debug_log "Fetching historical data from CoinGecko..."
    local response
    local url="$COINGECKO_HISTORICAL"
    
    # Add API key if configured
    if [[ -n "$COINGECKO_KEY" ]]; then
        url="${url}&x_cg_api_key=${COINGECKO_KEY}"
    fi
    
    response=$(curl -s -m 15 "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "Error: Failed to fetch historical data from CoinGecko" >&2
        echo "Historical data requires CoinGecko API which may be rate-limited" >&2
        echo "Try again in a few minutes or run without --plot for current price only" >&2
        exit 1
    fi
    
    debug_log "Historical data response length: ${#response} characters"
    
    local prices
    prices=$(echo "$response" | jq -r '.prices[][] | select(. != null)' 2>/dev/null | awk 'NR % 2 == 0')
    
    if [[ -z "$prices" ]]; then
        echo "Error: Invalid historical data format received" >&2
        debug_log "Raw response: $response"
        echo "Try running with DEBUG=1 ./btc-trck --plot for more information" >&2
        exit 1
    fi
    
    echo "$prices"
}

# Function to create ASCII plot
create_ascii_plot() {
    # Load config first to get the correct currency
    load_config
    
    local -a prices=()
    local line
    
    # Read prices into array
    while IFS= read -r line; do
        if [[ -n "$line" && "$line" != "null" ]]; then
            prices+=("$line")
        fi
    done < <(get_historical_data)
    
    if [[ ${#prices[@]} -eq 0 ]]; then
        echo "Error: No historical data available" >&2
        exit 1
    fi
    
    # Calculate min/max for scaling
    local min_price max_price
    min_price=$(printf "%.0f\n" "${prices[@]}" | sort -n | head -1)
    max_price=$(printf "%.0f\n" "${prices[@]}" | sort -n | tail -1)
    
    local price_range=$((max_price - min_price))
    if [[ $price_range -eq 0 ]]; then
        price_range=1
    fi
    
    local plot_height=20
    local plot_width=60
    local currency_symbol
    currency_symbol=$(get_currency_symbol)
    
    # Calculate average price for color coding
    local avg_price
    avg_price=$(awk 'BEGIN{sum=0; count=0} {sum+=$1; count++} END{printf "%.2f", sum/count}' <<< "$(printf "%s\n" "${prices[@]}")")
    
    echo -e "\n${BLUE}Bitcoin Price Chart (Last 30 Days)${NC}"
    echo -e "${YELLOW}Price Range: ${currency_symbol}${min_price} - ${currency_symbol}${max_price}${NC}"
    echo -e "${YELLOW}30 days average: ${currency_symbol}${avg_price}${NC}"
    echo -e "${YELLOW}Historical data from CoinGecko${NC}"
    
    # Create the plot data array with normalized values
    local -a plot_data=()
    for price in "${prices[@]}"; do
        local normalized
        normalized=$(awk "BEGIN {printf \"%.0f\", ($price - $min_price) * $plot_height / $price_range}")
        plot_data+=("$normalized")
    done
    
    # Print the chart from top to bottom
    for ((row = plot_height; row >= 0; row--)); do
        local y_label
        y_label=$(awk "BEGIN {printf \"${currency_symbol}%6.0f\", $min_price + ($row * $price_range / $plot_height)}")
        printf "%s " "$y_label"
        
        # Map each column to the corresponding data point
        for ((col = 0; col < plot_width; col++)); do
            # Calculate which data point this column represents
            local data_index
            if [[ ${#plot_data[@]} -gt 1 ]]; then
                data_index=$(awk "BEGIN {printf \"%.0f\", $col * (${#plot_data[@]} - 1) / ($plot_width - 1)}")
            else
                data_index=0
            fi
            
            # Ensure data_index is within bounds
            if [[ $data_index -ge ${#plot_data[@]} ]]; then
                data_index=$((${#plot_data[@]} - 1))
            fi
            
            # Get the actual price for this data point to determine color
            local actual_price="${prices[data_index]}"
            local color
            if (( $(awk "BEGIN {print ($actual_price >= $avg_price)}") )); then
                color="$GREEN"
            else
                color="$RED"
            fi
            
            # Plot the point with appropriate color
            if [[ ${plot_data[data_index]} -eq row ]]; then
                printf "${color}*${NC}"
            elif [[ ${plot_data[data_index]} -gt row ]]; then
                printf "${color}|${NC}"
            else
                printf " "
            fi
        done
        echo
    done
    
    # Print x-axis with proper day calculation (no negative days)
    printf "        "
    for ((i = 0; i < plot_width; i += 10)); do
        printf "%-10s" "|"
    done
    echo
    
    printf "        "
    for ((i = 0; i < plot_width; i += 10)); do
        # Calculate days ago ensuring no negative values
        local days_ago=$((30 - (i * 30 / (plot_width > 1 ? plot_width - 1 : 1))))
        if [[ $days_ago -lt 0 ]]; then
            days_ago=0
        fi
        printf "%-10s" "${days_ago}d"
    done
    echo -e "\n        ${YELLOW}Days ago${NC}\n"
}

# Function to get currency symbol
get_currency_symbol() {
    case "$CURRENCY" in
        EUR) echo "€" ;;
        USD) echo "$" ;;
        GBP) echo "£" ;;
        JPY) echo "¥" ;;
        *) echo "$CURRENCY " ;;
    esac
}

# Function to display current price with formatting
display_current_price() {
    # Load config first to get the correct currency
    load_config
    
    local price_info
    price_info=$(get_current_price)
    
    local current_price
    local source
    current_price=$(echo "$price_info" | cut -d'|' -f1)
    source=$(echo "$price_info" | cut -d'|' -f2)
    
    local currency_symbol
    currency_symbol=$(get_currency_symbol)
    
    echo -e "\n${BLUE}Current Bitcoin Price${NC}"
    echo -e "${GREEN}${currency_symbol}${current_price}${NC}"
    echo -e "${YELLOW}Data from ${source}${NC}\n"
}

# Function to show usage
show_usage() {
    echo "btc-trck - Bitcoin Price Tracker"
    echo "================================="
    echo ""
    echo "USAGE:"
    echo "  $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --plot                           Show price chart for the last 30 days"
    echo "  --config                         Show current configuration"
    echo "  --config.api <api>               Set preferred API"
    echo "  --config.currency <currency>     Set currency (must be quoted)"
    echo "  --config.coingecko <key>         Set CoinGecko API key"
    echo "  --config.binance <key>           Set Binance API key"
    echo "  --help, -h                       Show this help message"
    echo ""
    echo "SUPPORTED APIs:"
    echo "  coindesk                         CoinDesk API (most reliable)"
    echo "  binance                          Binance API (high uptime)"
    echo "  coingecko                        CoinGecko API (comprehensive)"
    echo "  \"\" (empty)                       Automatic fallback (default)"
    echo ""
    echo "SUPPORTED CURRENCIES:"
    echo "  EUR, USD, GBP, JPY, CAD, AUD, CHF, CNY, and many others"
    echo "  Note: Not all APIs support all currencies"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  DEBUG=1                          Enable debug output for troubleshooting"
    echo ""
    echo "EXAMPLES:"
    echo "  Basic usage:"
    echo "    $0                             Show current Bitcoin price"
    echo "    $0 --plot                      Show price with 30-day chart"
    echo ""
    echo "  Configuration:"
    echo "    $0 --config                    Show current settings"
    echo "    $0 --config.api coindesk       Set preferred API to CoinDesk"
    echo "    $0 --config.currency \"USD\"     Set currency to US Dollar"
    echo "    $0 --config.currency \"GBP\"     Set currency to British Pound"
    echo "    $0 --config.api \"\"              Use automatic API fallback"
    echo ""
    echo "  API keys (for higher rate limits):"
    echo "    $0 --config.coingecko \"your-key\"  Set CoinGecko API key"
    echo "    $0 --config.binance \"your-key\"    Set Binance API key"
    echo ""
    echo "  Troubleshooting:"
    echo "    DEBUG=1 $0                     Show debug information"
    echo "    DEBUG=1 $0 --plot              Debug with chart plotting"
    echo ""
    echo "FILES:"
    echo "  Configuration: $CONFIG_FILE"
    echo ""
    echo "NOTES:"
    echo "  - Script automatically creates config file on first run"
    echo "  - Uses multiple API fallbacks for maximum reliability"
    echo "  - Historical charts require CoinGecko API"
    echo "  - Currency values must be quoted when setting via command line"
    echo "  - API keys are optional but help avoid rate limiting"
}

# Main function
main() {
    check_dependencies
    
    case "${1:-}" in
        --plot)
            display_current_price
            create_ascii_plot
            ;;
        --config)
            show_config
            ;;
        --config.api)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --config.api requires a value" >&2
                echo "Available APIs: coindesk, binance, coingecko" >&2
                exit 1
            fi
            case "$2" in
                coindesk|binance|coingecko|"")
                    update_config "API" "$2"
                    ;;
                *)
                    echo "Error: Invalid API '$2'" >&2
                    echo "Available APIs: coindesk, binance, coingecko" >&2
                    exit 1
                    ;;
            esac
            ;;
        --config.currency)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --config.currency requires a value" >&2
                echo "Examples: ./btc-trck --config.currency \"USD\"" >&2
                exit 1
            fi
            # Convert to uppercase and store as string
            local currency_value
            currency_value=$(echo "$2" | tr '[:lower:]' '[:upper:]')
            update_config "CURRENCY" "$currency_value"
            ;;
        --config.coingecko)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --config.coingecko requires a value" >&2
                echo "Example: ./btc-trck --config.coingecko \"your-api-key\"" >&2
                exit 1
            fi
            update_config "COINGECKO_KEY" "$2"
            ;;
        --config.binance)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --config.binance requires a value" >&2
                echo "Example: ./btc-trck --config.binance \"your-api-key\"" >&2
                exit 1
            fi
            update_config "BINANCE_KEY" "$2"
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            display_current_price
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            show_usage >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
