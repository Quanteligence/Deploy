#!/usr/bin/env ruby
# encoding: utf-8

require "sqlite3"
require "mail"
require "net/http"
require "json"
require "uri"
require "base64"

DB_FILE = ARGV[0]
WALLET_ADDRESS = ARGV[1]
EMAIL_FROM = "noreply@flashusdt.com"
EMAIL_TO = "user@example.com"
SMTP_SERVER = "localhost"
TRON_NODE_URL = "https://nile.trongrid.io"

def initialize_database
  unless File.exist?(DB_FILE)
    db = SQLite3::Database.new(DB_FILE)
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY,
        wallet_address TEXT,
        tx_hash TEXT,
        created_at TEXT
      );
    SQL
    puts "Database and table 'transactions' created successfully!"
  else
    puts "Database already exists."
  end
end

def log_transaction(wallet_address, tx_hash)
  db = SQLite3::Database.new(DB_FILE)
  current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  db.execute("INSERT INTO transactions (wallet_address, tx_hash, created_at) VALUES (?, ?, ?)", [wallet_address, tx_hash, current_time])
end

def decode_error_message(encoded_message)
  if encoded_message.match?(/^[A-Za-z0-9+\/=]+$/)
    Base64.decode64(encoded_message)
  else
    encoded_message # Return as is if not Base64
  end
rescue StandardError => e
  "Error decoding message: #{e.message}"
end

def create_tron_token(wallet_address)
  uri = URI.parse("#{TRON_NODE_URL}/wallet/triggerconstantcontract")
  header = { 'Content-Type': 'application/json' }

  unless wallet_address =~ /^T[a-zA-Z0-9]{33}$/
    puts "Error: Invalid wallet address format."
    return
  end

  payload = {
    "contract_address" => "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf",  # Update with your contract
    "function_selector" => "createToken",
    "parameter" => wallet_address
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri, header)
  request.body = payload.to_json

  response = http.request(request)
  response_body = JSON.parse(response.body)

  if response_body["result"]["code"] == "OTHER_ERROR"
    error_message = response_body["result"]["message"]
    decoded_message = decode_error_message(error_message)
    puts "API Error: #{decoded_message}"
  else
    tx_hash = response_body.dig("transaction", "txID")
    if tx_hash
      puts "Transaction successful! TX Hash: #{tx_hash}"
      log_transaction(wallet_address, tx_hash)
    else
      puts "Unexpected response format: #{response_body}"
    end
  end
rescue JSON::ParserError
  puts "Invalid JSON response from the API: #{response.body}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end

initialize_database
create_tron_token(WALLET_ADDRESS)
