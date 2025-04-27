// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameRegistry.sol";

contract DeployGameRegistry is Script {
    GameGovernanceToken public token;
    GameRegistryTimelock public timelock;
    GameRegistryGovernor public governor;
    GameRegistry public registry;

    function run() external {
        // Load the private key from the environment variable
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // Get the deployer address
        address deployer = vm.addr(deployerKey);

        // Deploy the contracts
        deployContracts(deployer);

        // Configure the system
        configureSystem(deployer);

        vm.stopBroadcast();
    }

    function deployContracts(address admin) private {
        // 1. Deploy Governance Token
        token = new GameGovernanceToken();
        console.log("Governance Token deployed at:", address(token));

        // 2. Deploy Timelock
        // Setup timelock parameters
        uint256 minDelay = 1 days;
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        timelock = new GameRegistryTimelock(minDelay, proposers, executors, admin);
        console.log("Timelock deployed at:", address(timelock));

        // 3. Deploy Governor
        uint48 votingDelay = 1; // 1 block
        uint32 votingPeriod = 10; // 10 blocks
        uint256 quorumPercentage = 4; // 4%

        governor =
            new GameRegistryGovernor(IVotes(address(token)), timelock, votingDelay, votingPeriod, quorumPercentage);
        console.log("Governor deployed at:", address(governor));

        // 4. Deploy GameRegistry
        registry = new GameRegistry();
        console.log("GameRegistry deployed at:", address(registry));
    }

    function configureSystem(address admin) private {
        // 5. Setup roles and permissions
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        // Grant roles
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Anyone can execute

        // Transfer registry ownership to timelock
        registry.transferOwnership(address(timelock));

        // 6. Mint initial governance tokens to admin
        token.mint(admin, 1_000_000 * 1e18); // 1 million tokens

        // Only revoke admin role after everything else is set up
        timelock.revokeRole(adminRole, admin);
    }
}
