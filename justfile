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
execute-game:
    forge script \
        --chain sepolia \
        script/ExecuteGame.s.sol:ExecuteGameRegistration \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv

[group: 'contract-interaction']
check-proposal:
    forge script script/CheckProposal.s.sol:CheckProposalState \
        --rpc-url http://localhost:8545 \
        --private-key $PRIVATE_KEY \
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
verify:
    forge verify-contract \
        --chain-id 11155111 \
        --watch \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --compiler-version v0.8.26+commit.8a97fa7a \
        0xc83b139327BA47a9BAe64f9Fe0672185d85F38e5 \
        src/lib/GameRegistry.sol:GameRegistry

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