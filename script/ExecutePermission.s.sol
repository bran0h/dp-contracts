// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/IGameRegistry.sol";

contract ExecutePermission is Script {
    function run() external {
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address registryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
        address gameAddress = vm.envAddress("GAME_ADDRESS");
        address assetAddress = vm.envAddress("ASSET_ADDRESS");
        uint256 proposalId = vm.envUint("PERMISSION_PROPOSAL_ID");
        uint256 voterKey = vm.envUint("PRIVATE_KEY");
        string memory proposalDescription = vm.envString("PERMISSION_DESCRIPTION");

        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));
        GameGovernanceToken token = GameGovernanceToken(tokenAddress);

        // Check current state before proceeding
        IGovernor.ProposalState state = governor.state(proposalId);
        console.log("Current proposal state:", uint256(state));

        vm.startBroadcast(voterKey);

        // First, delegate votes to self if not already delegated
        if (token.delegates(vm.addr(voterKey)) == address(0)) {
            console.log("Delegating votes to self...");
            token.delegate(vm.addr(voterKey));
            console.log("Delegated votes to self");
        }

        if (state == IGovernor.ProposalState.Succeeded) {
            address[] memory targets = new address[](1);
            targets[0] = registryAddress;

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);

            bytes32[] memory attributes = new bytes32[](2);
            attributes[0] = keccak256("rpgame.item.haste");
            attributes[1] = keccak256("rpgame.item.damage");

            calldatas[0] = abi.encodeWithSelector(
                IGameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes
            );

            // Queue for execution
            governor.queue(targets, values, calldatas, keccak256(bytes(proposalDescription)));
            console.log("Proposal queued successfully");
        }
        // If proposal is queued and timelock elapsed, execute
        else if (state == IGovernor.ProposalState.Queued) {
            address[] memory targets = new address[](1);
            targets[0] = registryAddress;

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);

            bytes32[] memory attributes = new bytes32[](2);
            attributes[0] = keccak256("rpgame.item.haste");
            attributes[1] = keccak256("rpgame.item.damage");

            calldatas[0] = abi.encodeWithSelector(
                IGameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes
            );

            governor.execute(targets, values, calldatas, keccak256(bytes(proposalDescription)));
            console.log("Proposal executed successfully");
        } else {
            console.log("Proposal not in correct state for action");
            console.log("Required states: Active (for voting), Succeeded (for queueing), or Queued (for execution)");
        }

        vm.stopBroadcast();
    }
}
