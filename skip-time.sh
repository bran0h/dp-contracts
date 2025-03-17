#!/bin/bash

# Deploy contracts
echo "Skiping proposal time..."
# 1. Skip ahead some blocks (for voting delay)
cast rpc anvil_mine 2

# 2. Move time forward
cast rpc anvil_setNextBlockTimestamp $(( $(date +%s) + 3600 ))

# 3. Check the proposal state
cast call $GOVERNOR_ADDRESS "state(uint256)(uint8)" $PROPOSAL_ID