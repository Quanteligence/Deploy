#!/usr/bin/env bash

# Basic USDT Token Creator
# Version 1.1
# Author: basicfeatures
# License: MIT
# This script sets up the environment and runs the Ruby script to create USDT flash tokens.

# Configuration Variables
DB_FILE="transactions.db"  # SQLite3 database file to store transaction logs
EMAIL_FROM="noreply@flashusdt.com"  # Default email sender for confirmations
EMAIL_TO="user@example.com"  # Default recipient for transaction confirmations
SMTP_SERVER="localhost"  # OpenSMTPD server address
FLASH_TOKEN_DURATION=7  # Token validity duration in days
BINANCE_USERNAME="your_binance_username"  # Your Binance username for trading
BINANCE_API_KEY="your_binance_api_key"  # Your Binance API Key
BINANCE_API_SECRET="your_binance_api_secret"  # Your Binance API Secret
ETH_NODE_URL="https://your_eth_node"  # Your Ethereum node URL
TRON_NODE_URL="https://api.trongrid.io"  # Your Tron node URL

# Logging function
log_file="usdt_creator.log"
log() {
    echo "$(date): $1" >> $log_file
}

# Check if running on a supported OS
if [[ "$(uname)" != "Linux" && "$(uname)" != "Darwin" ]]; then
    echo "Error: This script is intended to run on Linux or MacOS only."
    exit 1
fi

# Install any missing dependencies
function install_dependencies() {
    echo "Ensuring Ruby, SQLite3, and sendmail are installed..."
    sudo apt-get update
    sudo apt-get install -y ruby sqlite3 sendmail
    gem install sqlite3 mail ethereum
    log "Dependencies installed successfully."
}

# Function to validate the wallet address format
validate_wallet_address() {
    while true; do
        read -p "Enter your Ethereum or Tron wallet address: " wallet_address
        if [[ "$wallet_address" =~ ^(0x[a-fA-F0-9]{40}|T[a-zA-Z0-9]{33})$ ]]; then
            echo "Valid wallet address."
            log "Entered wallet address: $wallet_address"
            break
        else
            echo "Invalid address. Please enter a valid Ethereum or Tron wallet address."
        fi
    done
}

# Run the Ruby script to create tokens
run_ruby_script() {
    ruby create_token.rb "$1"
}

# Start the script
install_dependencies
validate_wallet_address
run_ruby_script "$wallet_address"
log "USDT Token creation process completed."
