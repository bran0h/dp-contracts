#!/bin/bash

# Deploy contracts
echo "Proposing game..."
forge script script/ProposeGame.s.sol:ProposeGameRegistration \
    --rpc-url http://localhost:8545 \
    --broadcast
