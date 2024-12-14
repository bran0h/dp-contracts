#!/bin/bash

# Start anvil in the background
echo "Starting Anvil..."
anvil &
ANVIL_PID=$!

# Wait for anvil to start
sleep 2

# Get the first private key from anvil
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Deploy contracts
echo "Deploying contracts..."
forge script script/DeployGameSystem.s.sol:DeployGameSystem \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast

# Kill anvil
kill $ANVIL_PID