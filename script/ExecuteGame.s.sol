// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/IGameRegistry.sol";

contract ExecuteGameRegistration is Script {
    string constant REGISTER_DESCRIPTION = "Register RPGame in the GameRegistry";
    string constant PERMISSION_DESCRIPTION = "Grant sword attributes permissions to RPGame";

    function run() external {
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        uint256 voterKey = vm.envUint("PRIVATE_KEY");
        bool isRegistration = vm.envBool("IS_REGISTRATION");

        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));
        GameGovernanceToken token = GameGovernanceToken(tokenAddress);

        // Check current state before proceeding
        IGovernor.ProposalState state = governor.state(proposalId);
        console.log("Current proposal state:", uint256(state));

        vm.startBroadcast(voterKey);

        // First, delegate votes to self if not already delegated
        if (token.delegates(vm.addr(voterKey)) == address(0)) {
            token.delegate(vm.addr(voterKey));
            console.log("Delegated votes to self");
        }

        // If proposal is active, vote
        if (state == IGovernor.ProposalState.Active) {
            // My address
            console.log("My address:", vm.addr(voterKey));
            governor.castVote(proposalId, 1);
            console.log("Vote cast successfully");
        }
        // If proposal succeeded, queue it (if using timelock)
        else if (state == IGovernor.ProposalState.Succeeded) {
            string memory description = isRegistration ? REGISTER_DESCRIPTION : PERMISSION_DESCRIPTION;

            address[] memory targets = new address[](1);
            targets[0] = vm.envAddress("REGISTRY_ADDRESS");

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);

            if (isRegistration) {
                address gameAddress = vm.envAddress("GAME_ADDRESS");
                calldatas[0] = abi.encodeWithSelector(IGameRegistry.registerGame.selector, gameAddress);
            } else {
                address gameAddress = vm.envAddress("GAME_ADDRESS");
                address assetAddress = vm.envAddress("ASSET_ADDRESS");
                bytes32[] memory attributes = new bytes32[](2);
                attributes[0] = keccak256("rpgame.item.haste");
                attributes[1] = keccak256("rpgame.item.damage");

                calldatas[0] = abi.encodeWithSelector(
                    IGameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes
                );
            }

            // Queue for execution
            governor.queue(targets, values, calldatas, keccak256(bytes(description)));
            console.log("Proposal queued successfully");
        }
        // If proposal is queued and timelock elapsed, execute
        else if (state == IGovernor.ProposalState.Queued) {
            string memory description = isRegistration ? REGISTER_DESCRIPTION : PERMISSION_DESCRIPTION;

            address[] memory targets = new address[](1);
            targets[0] = vm.envAddress("REGISTRY_ADDRESS");

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);

            if (isRegistration) {
                address gameAddress = vm.envAddress("GAME_ADDRESS");
                calldatas[0] = abi.encodeWithSelector(IGameRegistry.registerGame.selector, gameAddress);
            } else {
                address gameAddress = vm.envAddress("GAME_ADDRESS");
                address assetAddress = vm.envAddress("ASSET_ADDRESS");
                bytes32[] memory attributes = new bytes32[](2);
                attributes[0] = keccak256("rpgame.item.haste");
                attributes[1] = keccak256("rpgame.item.damage");

                calldatas[0] = abi.encodeWithSelector(
                    IGameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes
                );
            }

            governor.execute(targets, values, calldatas, keccak256(bytes(description)));
            console.log("Proposal executed successfully");
        } else {
            console.log("Proposal not in correct state for action");
            console.log("Required states: Active (for voting), Succeeded (for queueing), or Queued (for execution)");
        }

        vm.stopBroadcast();
    }
}
