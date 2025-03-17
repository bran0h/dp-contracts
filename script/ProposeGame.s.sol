// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";

contract ProposeGameRegistration is Script {
    function run() external {
        // Load deployed contract addresses from environment
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address registryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
        address gameAddress = vm.envAddress("GAME_ADDRESS");
        address assetAddress = vm.envAddress("ASSET_ADDRESS");
        uint256 proposerKey = vm.envUint("PRIVATE_KEY");

        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));

        // Define attributes
        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = keccak256("rpgame.item.haste");
        attributes[1] = keccak256("rpgame.item.damage");

        vm.startBroadcast(proposerKey);

        // First proposal: Register the game
        bytes memory registerCalldata = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

        address[] memory targets = new address[](1);
        targets[0] = registryAddress;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = registerCalldata;

        uint256 registrationProposalId =
            governor.propose(targets, values, calldatas, "Register RPGame in the GameRegistry");

        console.log("Game Registration Proposal Created:");
        console.log("Proposal ID:", registrationProposalId);

        // Second proposal: Grant permissions
        bytes memory grantCalldata =
            abi.encodeWithSelector(GameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes);

        calldatas[0] = grantCalldata;

        uint256 permissionProposalId =
            governor.propose(targets, values, calldatas, "Grant sword attributes permissions to RPGame");

        console.log("\nPermission Grant Proposal Created:");
        console.log("Proposal ID:", permissionProposalId);

        vm.stopBroadcast();
    }
}
