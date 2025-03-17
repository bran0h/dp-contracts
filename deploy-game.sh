#!/bin/bash
# Get the first private key from anvil
PRIVATE_KEY="ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Deploy contracts
echo "Deploying contracts..."
echo "Private key: $PRIVATE_KEY"
forge script script/DeployGame.s.sol:DeployRPGame \
    --rpc-url http://localhost:8545 \
    --private-key "$PRIVATE_KEY" \
    --broadcast
