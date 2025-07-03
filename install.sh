#!/bin/bash
# btc-trck installer

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="btc-trck"

# Check if running as root for system install
if [[ $EUID -eq 0 ]]; then
    echo "Installing btc-trck system-wide..."
    INSTALL_DIR="/usr/local/bin"
else
    echo "Installing btc-trck for current user..."
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
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

# Install function
install_btc_trck() {
    echo "Checking dependencies..."
    check_dependencies
    
    echo "Installing btc-trck to $INSTALL_DIR..."
    cp btc-trck "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/btc-trck"
    
    echo "btc-trck installed successfully!"
    echo "Run 'btc-trck --help' to get started."
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        echo "Note: Add $INSTALL_DIR to your PATH:"
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
}

install_btc_trck
