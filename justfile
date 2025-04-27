set dotenv-load

default:
    just --list

[group: 'deploy']
deploy-system:
    # Deploy the system
    echo "Deploying system..."
    forge script \
        --chain sepolia \
        script/GameSystem.s.sol:DeployGameSystem \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv 
    # Add your deployment commands here
    echo "System deployed successfully!"

[group: 'deploy']
deploy-game:
    # Deploy the game
    echo "Deploying game..."
    forge script \
        --chain sepolia \
        script/DeployGame.s.sol:DeployRPGame \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv 
    # Add your deployment commands here
    echo "Game deployed successfully!"

[group: 'contract-interaction']
propose-game:
    forge script \
        --chain sepolia \
        script/ProposeGame.s.sol:ProposeGameRegistration \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv

[group: 'contract-interaction']
vote-game:
    export PROPOSAL_ID="$GAME_PROPOSAL_ID" && \
    forge script \
        --chain sepolia \
        script/VoteProposal.s.sol:VoteProposal \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        -vvvv

[group: 'contract-interaction']
vote-permission:
    export PROPOSAL_ID="$PERMISSION_PROPOSAL_ID" && \
    forge script \
        --chain sepolia \
        script/VoteProposal.s.sol:VoteProposal \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        -vvvv

[group: 'contract-interaction']
execute-game:
    forge script \
        --chain sepolia \
        script/ExecuteGame.s.sol:ExecuteGame \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        -vvvv

[group: 'contract-interaction']
execute-permission:
    forge script \
        --chain sepolia \
        script/ExecutePermission.s.sol:ExecutePermission \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        -vvvv

[group: 'contract-interaction']
check-game-proposal:
    export PROPOSAL_ID="$GAME_PROPOSAL_ID" && \
    forge script \
        --chain sepolia \
        script/CheckProposal.s.sol:CheckProposal \
        --rpc-url $SEPOLIA_RPC_URL \
        -vv

[group: 'contract-interaction']
check-permission-proposal:
    export PROPOSAL_ID="$PERMISSION_PROPOSAL_ID" && \
    forge script \
        --chain sepolia \
        script/CheckProposal.s.sol:CheckProposal \
        --rpc-url $SEPOLIA_RPC_URL \
        -vv

[group: 'anvil']
skip-time:
    # Deploy contracts
    echo "Skiping proposal time..."
    # 1. Skip ahead some blocks (for voting delay)
    cast rpc anvil_mine 2

    # 2. Move time forward
    cast rpc anvil_setNextBlockTimestamp $(( $(date +%s) + 3600 ))

    # 3. Check the proposal state
    cast call $GOVERNOR_ADDRESS "state(uint256)(uint8)" $PROPOSAL_ID

[group: 'anvil']
verify CONTRACT ADDRESS:
    forge verify-contract \
        --chain-id 11155111 \
        --watch \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --compiler-version v0.8.26+commit.8a97fa7a \
        "$ADDRESS" \
        "src/lib/$CONTRACT.sol:$CONTRACT"

[group: 'test']
test-integration:
    # Run integration tests
    echo "Running integration tests..."
    forge script \
        --chain sepolia \
        script/integration/IntegrationTest.s.sol:IntegrationTest \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv
    # Add your test commands here
    echo "Integration tests completed!"