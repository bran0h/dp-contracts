// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameAsset.sol";
import "../src/RPGame.sol";

contract DeployRPGame is Script {
    // Constants for attribute names
    bytes32 public constant HASTE_ATTR = keccak256("rpgame.item.haste");
    bytes32 public constant DAMAGE_ATTR = keccak256("rpgame.item.damage");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get existing GameRegistry address
        address gameRegistryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");

        // 1. Deploy GameAsset (Sword)
        GameAsset swordAsset = new GameAsset("RPGame Sword", "RPGSWD", gameRegistryAddress);
        console.log("Sword Asset deployed at:", address(swordAsset));

        // 2. Deploy RPGame with BaseGameImplementation parameters
        uint256 requiredApprovals = 3; // Number of approvals needed for proposals
        uint256 proposalTimeout = 7 days; // Proposal expires after 7 days
        uint256 updateTimelock = 1 days; // 1 day delay before updates take effect

        RPGame rpGame = new RPGame(gameRegistryAddress, requiredApprovals, proposalTimeout, updateTimelock);
        console.log("RPGame deployed at:", address(rpGame));

        // 3. Create attribute permissions array
        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = HASTE_ATTR;
        attributes[1] = DAMAGE_ATTR;

        // 4. Wait for governance to grant permissions
        console.log("\nPlease create a governance proposal with these parameters:");
        console.log("Target: GameRegistry at", gameRegistryAddress);
        console.log("Function: grantAssetPermission(address,address,bytes32[])");
        console.log("Parameters:");
        console.log("- game:", address(rpGame));
        console.log("- assetContract:", address(swordAsset));
        console.log("- attributes[0]:", uint256(attributes[0]));
        console.log("- attributes[1]:", uint256(attributes[1]));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("RPGame:", address(rpGame));
        console.log("Sword Asset:", address(swordAsset));
        console.log("Configuration:");
        console.log("- Required Approvals:", requiredApprovals);
        console.log("- Proposal Timeout:", proposalTimeout);
        console.log("- Update Timelock:", updateTimelock);
        console.log("Attributes to request:");
        console.log("- Haste:", vm.toString(HASTE_ATTR));
        console.log("- Damage:", vm.toString(DAMAGE_ATTR));
    }
}
