// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameAsset.sol";
import "../src/GoodGame.sol";

contract DeployGame is Script {
    // Constants for attribute names
    bytes32 public constant HASTE_ATTR = keccak256("GoodGame.item.haste");
    bytes32 public constant DAMAGE_ATTR = keccak256("GoodGame.item.damage");
    uint256 public constant REQUIRED_APPROVALS = 3; // Number of approvals needed for proposals
    uint256 public constant PROPOSAL_TIMEOUT = 7 days; // Proposal expires after 7 days
    uint256 public constant UPDATE_TIMELOCK = 1 days; // 1 day delay before updates take effect

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address gameRegistryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy GameAsset (Sword)
        GameAsset swordAsset = new GameAsset("GoodGame Sword", "GGSWD", gameRegistryAddress);
        console.log("Sword Asset deployed at:", address(swordAsset));

        // 2. Deploy GoodGame with BaseGameImplementation parameters
        GoodGame goodGame = new GoodGame(gameRegistryAddress, REQUIRED_APPROVALS, PROPOSAL_TIMEOUT, UPDATE_TIMELOCK);
        console.log("GoodGame deployed at:", address(goodGame));

        // 3. Create attribute permissions array
        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = HASTE_ATTR;
        attributes[1] = DAMAGE_ATTR;

        // 4. Wait for governance to grant permissions
        console.log("\nPlease create a governance proposal with these parameters:");
        console.log("Target: GameRegistry at", gameRegistryAddress);
        console.log("Function: grantAssetPermission(address,address,bytes32[])");
        console.log("Parameters:");
        console.log("- game:", address(goodGame));
        console.log("- assetContract:", address(swordAsset));
        console.log("- attributes[0]:", uint256(attributes[0]));
        console.log("- attributes[1]:", uint256(attributes[1]));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("GoodGame:", address(goodGame));
        console.log("Sword Asset:", address(swordAsset));
        console.log("Configuration:");
        console.log("- Required Approvals:", REQUIRED_APPROVALS);
        console.log("- Proposal Timeout:", PROPOSAL_TIMEOUT);
        console.log("- Update Timelock:", UPDATE_TIMELOCK);
        console.log("Attributes to request:");
        console.log("- Haste:", vm.toString(HASTE_ATTR));
        console.log("- Damage:", vm.toString(DAMAGE_ATTR));
    }
}
