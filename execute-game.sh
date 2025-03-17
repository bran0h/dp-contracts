#!/bin/bash

# Deploy contracts
echo "Executing game..."
forge script script/ExecuteGame.s.sol:ExecuteGameRegistration \
    --rpc-url http://localhost:8545 \
    --broadcast