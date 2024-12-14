// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameRegistry.sol";

contract GameSystemTest is Test {
    GameGovernanceToken public token;
    GameRegistryTimelock public timelock;
    GameRegistryGovernor public governor;
    GameRegistry public registry;

    address public deployer = address(1);
    address public user = address(2);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy contracts
        token = new GameGovernanceToken();

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new GameRegistryTimelock(1 days, proposers, executors, deployer);

        governor = new GameRegistryGovernor(
            IVotes(address(token)),
            timelock,
            1, // voting delay
            50400, // voting period
            4 // quorum
        );

        registry = new GameRegistry();

        // Setup roles
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);

        // Transfer registry ownership
        registry.transferOwnership(address(timelock));

        // Mint tokens
        token.mint(deployer, 1_000_000 * 1e18);

        vm.stopPrank();
    }

    function testProposalCreation() public {
        vm.startPrank(deployer);

        // Create proposal to register a game
        address gameAddress = address(123);

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
}
