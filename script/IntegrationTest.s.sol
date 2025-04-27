// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/GameAsset.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/RPGame.sol";

contract IntegrationTest is Script {
    // Contract interfaces
    GameGovernanceToken public token;
    GameRegistryTimelock public timelock;
    GameRegistryGovernor public governor;
    GameRegistry public registry;
    RPGame public rpGame;
    GameAsset public asset;

    // Game attributes
    bytes32 constant HASTE_ATTR = keccak256("rpgame.item.haste");
    bytes32 constant DAMAGE_ATTR = keccak256("rpgame.item.damage");
    bytes32 constant SWORD_TYPE = keccak256("SWORD");

    // User addresses
    address public player;
    address public upgrader1;
    address public upgrader2;

    function setUp() private {
        // Load addresses from env
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address timelockAddress = vm.envAddress("TIMELOCK_ADDRESS");
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address registryAddress = vm.envAddress("GAME_REGISTRY_ADDRESS");
        address rpGameAddress = vm.envAddress("GAME_ADDRESS");
        address assetAddress = vm.envAddress("ASSET_ADDRESS");

        // Load user addresses
        player = vm.envAddress("PLAYER_ADDRESS");
        upgrader1 = vm.envAddress("UPGRADER1_ADDRESS");
        upgrader2 = vm.envAddress("UPGRADER2_ADDRESS");

        // Initialize contract interfaces
        token = GameGovernanceToken(tokenAddress);
        timelock = GameRegistryTimelock(payable(timelockAddress));
        governor = GameRegistryGovernor(payable(governorAddress));
        registry = GameRegistry(registryAddress);
        rpGame = RPGame(rpGameAddress);
        asset = GameAsset(assetAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Setup contracts and addresses
        setUp();

        console.log("Starting integration test...");

        // Test sword minting and attribute updates
        testSwordFlow();

        // Test governance proposal
        testGovernanceProposal();

        console.log("Integration test completed");

        vm.stopBroadcast();
    }

    function testSwordFlow() private {
        // Mint a sword
        uint256 tokenId = 1;
        mintSword(tokenId);

        // Read initial attributes
        (uint256 initialHaste, uint256 initialDamage) = rpGame.getSwordAttributes(address(asset), tokenId);
        console.log("Initial sword attributes - Haste:", initialHaste, "Damage:", initialDamage);

        // Update sword attributes directly
        updateSwordAttributes(tokenId, 500, 2500);

        // Read updated attributes
        (uint256 updatedHaste, uint256 updatedDamage) = rpGame.getSwordAttributes(address(asset), tokenId);
        console.log("Updated sword attributes - Haste:", updatedHaste, "Damage:", updatedDamage);

        // Create, approve and execute an upgrade proposal
        proposeAndExecuteUpgrade(tokenId, 700, 5000);

        // Read final attributes
        (uint256 finalHaste, uint256 finalDamage) = rpGame.getSwordAttributes(address(asset), tokenId);
        console.log("Final sword attributes - Haste:", finalHaste, "Damage:", finalDamage);
    }

    function mintSword(uint256 tokenId) private {
        // Need to mint from the game contract to have proper permissions
        vm.startPrank(address(rpGame));

        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = HASTE_ATTR;
        attributes[1] = DAMAGE_ATTR;

        bytes[] memory values = new bytes[](2);
        values[0] = abi.encode(uint256(100)); // Initial haste
        values[1] = abi.encode(uint256(500)); // Initial damage

        asset.mint(player, tokenId, attributes, values);
        console.log("Sword minted to:", player, "with tokenId:", tokenId);

        vm.stopPrank();
    }

    function updateSwordAttributes(uint256 tokenId, uint256 haste, uint256 damage) private {
        rpGame.updateSwordAttributes(address(asset), tokenId, haste, damage);
        console.log("Sword attributes updated:");
        console.log("Token ID:", tokenId);
        console.log("Haste:", haste);
        console.log("Damage:", damage);
    }

    function proposeAndExecuteUpgrade(uint256 tokenId, uint256 newHaste, uint256 newDamage) private {
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

    function testGovernanceProposal() private {
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

        console.log("Further governance actions would be required to complete this process");
    }
}
