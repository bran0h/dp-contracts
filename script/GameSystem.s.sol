// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistryTimelock.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameRegistry.sol";

contract DeployGameSystem is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Governance Token
        GameGovernanceToken token = new GameGovernanceToken();
        console.log("Governance Token deployed at:", address(token));

        // 2. Deploy Timelock
        // Setup timelock parameters
        uint256 minDelay = 1 days;
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        GameRegistryTimelock timelock = new GameRegistryTimelock(
            minDelay,
            proposers,
            executors,
            msg.sender // admin
        );
        console.log("Timelock deployed at:", address(timelock));

        // 3. Deploy Governor
        uint48 votingDelay = 1; // 1 block
        uint32 votingPeriod = 50400; // ~1 week
        uint256 quorumPercentage = 4; // 4%

        GameRegistryGovernor governor =
            new GameRegistryGovernor(IVotes(address(token)), timelock, votingDelay, votingPeriod, quorumPercentage);
        console.log("Governor deployed at:", address(governor));

        // 4. Deploy GameRegistry
        GameRegistry registry = new GameRegistry();
        console.log("GameRegistry deployed at:", address(registry));

        // 5. Setup roles and permissions
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        // Grant roles
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Anyone can execute
        timelock.revokeRole(adminRole, msg.sender);

        // Transfer registry ownership to timelock
        registry.transferOwnership(address(timelock));

        // 6. Mint initial governance tokens if needed
        token.mint(msg.sender, 1_000_000 * 1e18); // 1 million tokens

        vm.stopBroadcast();
    }
}
