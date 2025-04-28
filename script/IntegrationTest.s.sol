// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/GameAsset.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/GoodGame.sol";

contract IntegrationTest is Script {
    // Contract interfaces
    GameGovernanceToken public token;
    GameRegistryTimelock public timelock;
    GameRegistryGovernor public governor;
    GameRegistry public registry;
    GoodGame public goodGame;
    GameAsset public asset;

    // Game attributes
    bytes32 constant HASTE_ATTR = keccak256("GoodGame.item.haste");
    bytes32 constant DAMAGE_ATTR = keccak256("GoodGame.item.damage");
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
        address goodGameAddress = vm.envAddress("GAME_ADDRESS");
        address assetAddress = vm.envAddress("ASSET_ADDRESS");

        // Load user addresses
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // Convert private key to address
        player = vm.addr(privateKey);
        upgrader1 = vm.envAddress("UPGRADER1_ADDRESS");
        upgrader2 = vm.envAddress("UPGRADER2_ADDRESS");

        // Initialize contract interfaces
        token = GameGovernanceToken(tokenAddress);
        timelock = GameRegistryTimelock(payable(timelockAddress));
        governor = GameRegistryGovernor(payable(governorAddress));
        registry = GameRegistry(registryAddress);
        goodGame = GoodGame(goodGameAddress);
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
        uint256 tokenId = vm.envUint("NEW_TOKEN_ID");
        mintSword(tokenId);

        // Read initial attributes
        (uint256 initialHaste, uint256 initialDamage) = goodGame.getSwordAttributes(address(asset), tokenId);
        console.log("Initial sword attributes - Haste:", initialHaste, "Damage:", initialDamage);

        // Update sword attributes directly
        updateSwordAttributes(tokenId, 500, 2500);

        // Read updated attributes
        (uint256 updatedHaste, uint256 updatedDamage) = goodGame.getSwordAttributes(address(asset), tokenId);
        console.log("Updated sword attributes - Haste:", updatedHaste, "Damage:", updatedDamage);
    }

    function mintSword(uint256 tokenId) private {
        goodGame.createSword(player, tokenId, 100, 500);
        console.log("Sword minted to:", player, "with tokenId:", tokenId);
    }

    function updateSwordAttributes(uint256 tokenId, uint256 haste, uint256 damage) private {
        goodGame.updateSwordAttributes(address(asset), tokenId, haste, damage);
        console.log("Sword attributes updated:");
        console.log("Token ID:", tokenId);
        console.log("Haste:", haste);
        console.log("Damage:", damage);
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
