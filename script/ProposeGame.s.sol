// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
        attributes[0] = keccak256("GoodGame.item.haste");
        attributes[1] = keccak256("GoodGame.item.damage");

        vm.startBroadcast(proposerKey);

        // First proposal: Register the game
        bytes memory registerCalldata = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

        address[] memory targets = new address[](1);
        targets[0] = registryAddress;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = registerCalldata;

        string memory gameProposalDescription = string(
            abi.encodePacked("Register GoodGame in the GameRegistry. Timestamp:", Strings.toString(block.timestamp))
        );

        uint256 registrationProposalId = governor.propose(targets, values, calldatas, gameProposalDescription);

        console.log("Game Registration Proposal Created:");
        console.log("GAME_PROPOSAL_ID=", registrationProposalId);
        console.log("GAME_DESCRIPTION=", gameProposalDescription);

        // Second proposal: Grant permissions
        bytes memory grantCalldata =
            abi.encodeWithSelector(GameRegistry.grantAssetPermission.selector, gameAddress, assetAddress, attributes);

        calldatas[0] = grantCalldata;

        string memory permissionProposalDescription = string(
            abi.encodePacked(
                "Grant sword attributes permissions to GoodGame. Timestamp:", Strings.toString(block.timestamp)
            )
        );

        uint256 permissionProposalId = governor.propose(targets, values, calldatas, permissionProposalDescription);

        console.log("\nPermission Grant Proposal Created:");
        console.log("PERMISSION_PROPOSAL_ID=", permissionProposalId);
        console.log("PERMISSION_DESCRIPTION=", permissionProposalDescription);

        vm.stopBroadcast();
    }
}
