// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/lib/GameRegistry.sol";
import "../../src/lib/GameAsset.sol";
import "../../src/lib/GameGovernanceToken.sol";
import "../../src/lib/GameRegistryTimelock.sol";
import "../../src/lib/GameRegistryGovernor.sol";
import "../../src/RPGame.sol";

contract IntegrationTest is Script {
    // Contract addresses (fill these in after deployment)
    address public tokenAddress = vm.envAddress("TOKEN_ADDRESS");
    address public timelockAddress = vm.envAddress("TIMELOCK_ADDRESS");
    address public governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
    address public registryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
    address public rpGameAddress = vm.envAddress("GAME_ADDRESS");
    address public assetAddress = vm.envAddress("ASSET_ADDRESS");

    // Game attributes
    bytes32 constant HASTE_ATTR = keccak256("rpgame.item.haste");
    bytes32 constant DAMAGE_ATTR = keccak256("rpgame.item.damage");
    bytes32 constant SWORD_TYPE = keccak256("SWORD");

    // User addresses (replace with your own addresses)
    address public player = vm.envAddress("PLAYER_ADDRESS");
    address public upgrader1 = vm.envAddress("UPGRADER1_ADDRESS");
    address public upgrader2 = vm.envAddress("UPGRADER2_ADDRESS");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Initialize contract interfaces
        GameGovernanceToken token = GameGovernanceToken(tokenAddress);
        GameRegistryTimelock timelock = GameRegistryTimelock(payable(timelockAddress));
        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));
        GameRegistry registry = GameRegistry(registryAddress);
        RPGame rpGame = RPGame(rpGameAddress);
        GameAsset asset = GameAsset(assetAddress);

        console.log("Starting integration test...");

        // Mint a sword with initial attributes
        mintSword(rpGame, asset, player, 1);

        // Read initial attributes
        (uint256 initialHaste, uint256 initialDamage) = rpGame.getSwordAttributes(assetAddress, 1);
        console.log("Initial sword attributes - Haste:", initialHaste, "Damage:", initialDamage);

        // Update sword attributes directly
        updateSwordAttributes(rpGame, 1, 500, 2500);

        // Read updated attributes
        (uint256 updatedHaste, uint256 updatedDamage) = rpGame.getSwordAttributes(assetAddress, 1);
        console.log("Updated sword attributes - Haste:", updatedHaste, "Damage:", updatedDamage);

        // Create, approve and execute an upgrade proposal
        proposeAndExecuteUpgrade(rpGame, 1, 700, 5000);

        // Read final attributes
        (uint256 finalHaste, uint256 finalDamage) = rpGame.getSwordAttributes(assetAddress, 1);
        console.log("Final sword attributes - Haste:", finalHaste, "Damage:", finalDamage);

        // Demo governance proposal to register a new game
        createGovernanceProposal(registry, governor);

        console.log("Integration test completed");

        vm.stopBroadcast();
    }

    function mintSword(RPGame rpGame, GameAsset asset, address to, uint256 tokenId) internal {
        // Need to mint from the game contract to have proper permissions
        vm.startPrank(address(rpGame));

        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = HASTE_ATTR;
        attributes[1] = DAMAGE_ATTR;

        bytes[] memory values = new bytes[](2);
        values[0] = abi.encode(uint256(100)); // Initial haste
        values[1] = abi.encode(uint256(500)); // Initial damage

        asset.mint(to, tokenId, attributes, values);
        console.log("Sword minted to:", to, "with tokenId:", tokenId);

        vm.stopPrank();
    }

    function updateSwordAttributes(RPGame rpGame, uint256 tokenId, uint256 haste, uint256 damage) internal {
        rpGame.updateSwordAttributes(assetAddress, tokenId, haste, damage);
        console.log("Sword attributes updated - Token:", tokenId, "Haste:", haste, "Damage:", damage);
    }

    function proposeAndExecuteUpgrade(RPGame rpGame, uint256 tokenId, uint256 newHaste, uint256 newDamage) internal {
        // Create upgrade proposal
        address sourceGame = address(0); // Arbitrary source game for example

        bytes32[] memory upgradeAttributes = new bytes32[](2);
        upgradeAttributes[0] = HASTE_ATTR;
        upgradeAttributes[1] = DAMAGE_ATTR;

        bytes[] memory upgradeValues = new bytes[](2);
        upgradeValues[0] = abi.encode(newHaste);
        upgradeValues[1] = abi.encode(newDamage);

        bytes32 proposalId = rpGame.proposeUpgrade(sourceGame, tokenId, upgradeAttributes, upgradeValues);
        console.log("Upgrade proposed with ID:", vm.toString(proposalId));

        // First approval
        vm.startPrank(upgrader1);
        rpGame.approveUpgrade(proposalId);
        console.log("Upgrade approved by upgrader1");
        vm.stopPrank();

        // Second approval - should execute the upgrade
        vm.startPrank(upgrader2);
        rpGame.approveUpgrade(proposalId);
        console.log("Upgrade approved by upgrader2 and executed");
        vm.stopPrank();
    }

    function createGovernanceProposal(GameRegistry registry, GameRegistryGovernor governor) internal {
        // Create a mock game to register
        address mockGame = address(0x1234);

        // Create proposal to register a new game
        bytes memory callData = abi.encodeWithSelector(GameRegistry.registerGame.selector, mockGame);

        address[] memory targets = new address[](1);
        targets[0] = address(registry);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = callData;

        string memory description = "Register new mock game";

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Governance proposal created with ID:", proposalId);

        // Note: In a real scenario, you would need to:
        // 1. Wait for the voting delay to pass
        // 2. Cast votes during the voting period
        // 3. Queue the proposal if it passes
        // 4. Wait for the timelock delay
        // 5. Execute the proposal

        console.log("Further governance actions would be required to complete this process");
    }
}
