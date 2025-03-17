#!/bin/bash

# Deploy contracts
echo "Executing game..."
PRIVATE_KEY="ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

forge script script/CheckProposal.s.sol:CheckProposalState \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    -vv