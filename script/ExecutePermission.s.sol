// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/IGameRegistry.sol";

contract ExecutePermission is Script {
    // Define these as contract state variables instead of local variables
    GameRegistryGovernor governor;
    GameRegistryTimelock timelock;
    GameGovernanceToken token;
    address registryAddress;
    address gameAddress;
    address assetAddress;
    bytes32 descriptionHash;
    uint256 proposalId;
    bytes32[] attributes;

    function run() external {
        // Load environment variables
        uint256 voterKey = vm.envUint("PRIVATE_KEY");
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        registryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
        proposalId = vm.envUint("PERMISSION_PROPOSAL_ID");
        gameAddress = vm.envAddress("GAME_ADDRESS");
        assetAddress = vm.envAddress("ASSET_ADDRESS");
        string memory proposalDescription = vm.envString("PERMISSION_DESCRIPTION");

        // Set up contract instances
        governor = GameRegistryGovernor(payable(governorAddress));
        timelock = GameRegistryTimelock(payable(governor.timelock()));
        token = GameGovernanceToken(tokenAddress);

        // Initialize attributes
        attributes = new bytes32[](2);
        attributes[0] = keccak256("GoodGame.item.haste");
        attributes[1] = keccak256("GoodGame.item.damage");

        // Compute hash once
        descriptionHash = keccak256(bytes(proposalDescription));

        // Check current state
        IGovernor.ProposalState state = governor.state(proposalId);
        console.log("Current proposal state:", uint256(state));

        vm.startBroadcast(voterKey);

        // Delegate votes check
        checkAndDelegateVotes(voterKey);

        // Process proposal based on state
        if (state == IGovernor.ProposalState.Succeeded) {
            queueProposal();
        } else if (state == IGovernor.ProposalState.Queued) {
            executeProposal();
        } else {
            logProposalState(state);
        }

        vm.stopBroadcast();
    }

    function checkAndDelegateVotes(uint256 voterKey) internal {
        if (token.delegates(vm.addr(voterKey)) == address(0)) {
            console.log("Delegating votes to self...");
            token.delegate(vm.addr(voterKey));
            console.log("Delegated votes to self!");
        }
    }

    function queueProposal() internal {
        console.log("Proposal succeeded, proceeding to queue...");

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = getProposalParams();

        // Queue for execution
        governor.queue(targets, values, calldatas, descriptionHash);
        console.log("Proposal queued successfully");
    }

    function executeProposal() internal {
        console.log("Proposal queued, proceeding to execute...");

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = getProposalParams();

        // Calculate the operation ID
        bytes32 operationId = getOperationId(targets, values, calldatas);

        // Check timelock status
        checkTimelockStatus(operationId);

        // Execute if ready
        uint8 operationState = uint8(timelock.getOperationState(operationId));
        if (operationState == 2) {
            governor.execute(targets, values, calldatas, descriptionHash);
            console.log("Proposal executed successfully");
        } else {
            console.log("Cannot execute: operation not in Ready state");
        }
    }

    function getProposalParams()
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);
        targets[0] = registryAddress;

        values = new uint256[](1);
        values[0] = 0;

        calldatas = new bytes[](1);
        calldatas[0] =
            abi.encodeWithSelector(IGameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes);

        return (targets, values, calldatas);
    }

    function getOperationId(address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
        internal
        view
        returns (bytes32)
    {
        // In OpenZeppelin's implementation, when queueing through Governor,
        // it uses hashOperationBatch even for single operations
        return timelock.hashOperationBatch(
            targets,
            values,
            calldatas,
            0, // predecessor (usually 0 for simple operations)
            bytes20(address(governor)) ^ descriptionHash // salt
        );
    }

    function checkTimelockStatus(bytes32 operationId) internal view {
        console.log("Current timestamp:", block.timestamp);
        console.log("Operation ready at:", timelock.getTimestamp(operationId));
        console.log("Minimum delay:", timelock.getMinDelay());

        uint8 operationState = uint8(timelock.getOperationState(operationId));
        console.log("Operation state:", operationState);
        console.log("Operation state meanings:");
        console.log("0: Unset (not found)");
        console.log("1: Pending (waiting delay)");
        console.log("2: Ready (can execute)");
        console.log("3: Done (already executed)");
        console.log("4: Cancelled");

        if (operationState == 1) {
            console.log("Operation is still pending. Need to wait until:", timelock.getTimestamp(operationId));
            uint256 waitTime = timelock.getTimestamp(operationId) - block.timestamp;
            console.log("Seconds to wait:", waitTime);
        }
    }

    function logProposalState(IGovernor.ProposalState state) internal pure {
        console.log("Proposal not in correct state for action");
        console.log("Current state:", uint256(state));
        console.log("State meaning:");
        console.log("0=Pending, 1=Active, 2=Canceled, 3=Defeated, 4=Succeeded, 5=Queued, 6=Expired, 7=Executed");
    }
}
