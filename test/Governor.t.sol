// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";

contract GameRegistryGovernorTest is Test {
    GameRegistryGovernor public governor;
    GameRegistryTimelock public timelock;
    GameGovernanceToken public token;
    GameRegistry public registry;

    address public admin = address(1);
    address public proposer = address(2);
    address public voter1 = address(3);
    address public voter2 = address(4);
    address public voter3 = address(5);

    uint256 public constant INITIAL_SUPPLY = 10000 ether;
    uint48 public constant VOTING_DELAY = 1; // 1 block
    uint32 public constant VOTING_PERIOD = 50; // 50 blocks
    uint256 public constant MIN_DELAY = 2 days;
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10%

    function setUp() public {
        vm.startPrank(admin);

        // Deploy contracts
        token = new GameGovernanceToken();

        // Mint tokens to voters
        token.mint(proposer, INITIAL_SUPPLY / 4);
        token.mint(voter1, INITIAL_SUPPLY / 4);
        token.mint(voter2, INITIAL_SUPPLY / 4);
        token.mint(voter3, INITIAL_SUPPLY / 4);

        // Set up timelock
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new GameRegistryTimelock(MIN_DELAY, proposers, executors, admin);

        // Set up governor
        governor =
            new GameRegistryGovernor(IVotes(address(token)), timelock, VOTING_DELAY, VOTING_PERIOD, QUORUM_PERCENTAGE);

        // Deploy registry
        registry = new GameRegistry();

        // Setup roles in timelock
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0)); // Zero address means anyone can execute
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), admin);

        // Transfer registry ownership to timelock
        registry.transferOwnership(address(timelock));

        vm.stopPrank();

        // Self-delegate tokens to activate voting power
        vm.startPrank(proposer);
        token.delegate(proposer);
        vm.stopPrank();

        vm.startPrank(voter1);
        token.delegate(voter1);
        vm.stopPrank();

        vm.startPrank(voter2);
        token.delegate(voter2);
        vm.stopPrank();

        vm.startPrank(voter3);
        token.delegate(voter3);
        vm.stopPrank();
    }

    function testProposalCreation() public {
        vm.startPrank(proposer);

        // Create a proposal to register a new game
        address gameAddress = address(0x123);

        bytes memory callData = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

        address[] memory targets = new address[](1);
        targets[0] = address(registry);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = callData;

        string memory description = "Register new game";

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertGt(proposalId, 0);

        vm.stopPrank();
    }

    function testProposalLifecycle() public {
        // Create a proposal
        vm.startPrank(proposer);

        address gameAddress = address(0x123);
        bytes memory callData = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

        address[] memory targets = new address[](1);
        targets[0] = address(registry);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = callData;

        string memory description = "Register new game";
        bytes32 descriptionHash = keccak256(bytes(description));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Check initial state
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        // Cast votes
        vm.prank(voter1);
        governor.castVote(proposalId, 1); // Vote yes

        vm.prank(voter2);
        governor.castVote(proposalId, 1); // Vote yes

        vm.prank(voter3);
        governor.castVote(proposalId, 0); // Vote no

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        // Queue the proposal
        vm.prank(proposer);
        governor.queue(targets, values, calldatas, descriptionHash);

        // Check that it's queued
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        // Move past timelock
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute the proposal
        vm.prank(proposer);
        governor.execute(targets, values, calldatas, descriptionHash);

        // Check that it's executed
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));

        // Verify the game was registered
        bool isGameRegistered = false;
        for (uint256 i = 0; i < 10; i++) {
            try registry.registeredGames(i) returns (address regGame) {
                if (regGame == gameAddress) {
                    isGameRegistered = true;
                    break;
                }
            } catch {
                break;
            }
        }

        assertTrue(isGameRegistered, "Game was not registered after proposal execution");
    }

    function testFailedProposal() public {
        // Create a proposal
        vm.startPrank(proposer);

        address gameAddress = address(0x123);
        bytes memory callData = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

        address[] memory targets = new address[](1);
        targets[0] = address(registry);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = callData;

        string memory description = "Register new game";

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Move to active state
        vm.roll(block.number + VOTING_DELAY + 1);

        // Cast votes (majority against)
        vm.prank(voter1);
        governor.castVote(proposalId, 0); // Vote no

        vm.prank(voter2);
        governor.castVote(proposalId, 0); // Vote no

        vm.prank(voter3);
        governor.castVote(proposalId, 1); // Vote yes

        // Move past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Get the current state of the proposal
        IGovernor.ProposalState currentState = governor.state(proposalId);

        // Should be in Defeated state
        assertTrue(currentState == IGovernor.ProposalState.Defeated, "Proposal should be in Defeated state");

        // Verify we cannot queue a defeated proposal
        // We're expecting a specific Governor error about unexpected proposal state
        bytes memory encodedError = abi.encodeWithSignature(
            "GovernorUnexpectedProposalState(uint256,uint8,uint256)",
            proposalId,
            uint8(IGovernor.ProposalState.Defeated),
            uint256(2 ^ 4)
        ); // Usually a bitmask of allowed states

        vm.expectRevert(encodedError);

        string memory descString = "Register new game";
        bytes32 descHash = keccak256(bytes(descString));
        governor.queue(targets, values, calldatas, descHash);
    }

    function testGrantAssetPermission() public {
        // Create a game first
        address gameAddress = address(0x123);

        // Step 1: Register the game
        {
            bytes memory callData = abi.encodeWithSelector(GameRegistry.registerGame.selector, gameAddress);

            address[] memory targets = new address[](1);
            targets[0] = address(registry);

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);
            calldatas[0] = callData;

            vm.prank(proposer);
            uint256 proposalId = governor.propose(targets, values, calldatas, "Register game");

            // Skip to voting and pass proposal
            vm.roll(block.number + VOTING_DELAY + 1);

            vm.prank(voter1);
            governor.castVote(proposalId, 1);

            vm.prank(voter2);
            governor.castVote(proposalId, 1);

            vm.roll(block.number + VOTING_PERIOD + 1);

            bytes32 descHash = keccak256(bytes("Register game"));

            vm.prank(proposer);
            governor.queue(targets, values, calldatas, descHash);

            vm.warp(block.timestamp + MIN_DELAY + 1);

            vm.prank(proposer);
            governor.execute(targets, values, calldatas, descHash);
        }

        // Step 2: Grant asset permission
        {
            address assetContract = address(0x456);

            bytes32[] memory attributes = new bytes32[](2);
            attributes[0] = keccak256("health");
            attributes[1] = keccak256("damage");

            bytes memory callData = abi.encodeWithSelector(
                GameRegistry.grantAssetPermission.selector, gameAddress, assetContract, attributes
            );

            address[] memory targets = new address[](1);
            targets[0] = address(registry);

            uint256[] memory values = new uint256[](1);
            values[0] = 0;

            bytes[] memory calldatas = new bytes[](1);
            calldatas[0] = callData;

            vm.prank(proposer);
            uint256 proposalId = governor.propose(targets, values, calldatas, "Grant permission");

            // Skip to voting and pass proposal
            vm.roll(block.number + VOTING_DELAY + 1);

            vm.prank(voter1);
            governor.castVote(proposalId, 1);

            vm.prank(voter2);
            governor.castVote(proposalId, 1);

            vm.roll(block.number + VOTING_PERIOD + 1);

            bytes32 descHash = keccak256(bytes("Grant permission"));

            vm.prank(proposer);
            governor.queue(targets, values, calldatas, descHash);

            vm.warp(block.timestamp + MIN_DELAY + 1);

            vm.prank(proposer);
            governor.execute(targets, values, calldatas, descHash);

            // Verify permissions were granted
            assertTrue(registry.hasPermissions(gameAddress, assetContract, attributes));
        }
    }
}
