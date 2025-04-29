// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/GameAsset.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/GoodGame.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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

        // Test governance proposal
        console.log("Testing governance proposal to register mock game...");
        testGovernanceProposal();

        // Test sword minting and attribute updates
        console.log("Testing sword minting and attribute updates...");
        testSwordFlow();

        console.log("Integration test completed");
        vm.stopBroadcast();
    }

    function testSwordFlow() private {
        // Mint a sword
        uint256 tokenId = vm.envUint("NEW_TOKEN_ID");
        mintSword(tokenId);

        // Read initial attributes
        (uint256 initialHaste, uint256 initialDamage) = goodGame.getSwordAttributes(address(asset), tokenId);
        console.log("On-chain sword attributes - Haste:", initialHaste, "Damage:", initialDamage);

        // Update sword attributes directly
        updateSwordAttributes(tokenId, 500, 2500);

        // Read updated attributes
        (uint256 updatedHaste, uint256 updatedDamage) = goodGame.getSwordAttributes(address(asset), tokenId);
        console.log("Updated on-chain sword attributes - Haste:", updatedHaste, "Damage:", updatedDamage);
    }

    function mintSword(uint256 tokenId) private {
        console.log("Minting sword with tokenId:", tokenId);
        console.log("Haste: 100");
        console.log("Damage: 500");
        goodGame.createSword(player, tokenId, 100, 500);
        console.log("Sword minted to:", player, "with tokenId:", tokenId);
    }

    function updateSwordAttributes(uint256 tokenId, uint256 haste, uint256 damage) private {
        console.log("Updating sword attributes for tokenId:", tokenId);
        console.log("New Haste:", haste);
        console.log("New Damage:", damage);
        goodGame.updateSwordAttributes(address(asset), tokenId, haste, damage);
        console.log("Sword attributes updated!");
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

        string memory description =
            string(abi.encodePacked("Register new mock game. Timestamp:", Strings.toString(block.timestamp)));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Governance proposal created with ID:", proposalId);

        // Get governance state
        IGovernor.ProposalState state = governor.state(proposalId);

        // Get timing information
        uint256 snapshot = governor.proposalSnapshot(proposalId);
        uint256 deadline = governor.proposalDeadline(proposalId);
        uint256 currentBlock = block.number;
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        console.log("Current block:", currentBlock);
        console.log("Proposal snapshot (start):", snapshot);
        console.log("Proposal deadline:", deadline);
        console.log("For votes:", forVotes);
        console.log("Against votes:", againstVotes);
        console.log("Abstain votes:", abstainVotes);
        console.log("Current state:", uint256(state));
        console.log("State meaning:");
        console.log("0=Pending, 1=Active, 2=Canceled, 3=Defeated, 4=Succeeded, 5=Queued, 6=Expired, 7=Executed");
    }
}
