// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";
import "../src/lib/GameGovernanceToken.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/IGameRegistry.sol";

contract VoteProposal is Script {
    function run() external {
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        uint256 voterKey = vm.envUint("PRIVATE_KEY");

        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));
        GameGovernanceToken token = GameGovernanceToken(tokenAddress);

        // Check current state before proceeding
        IGovernor.ProposalState state = governor.state(proposalId);
        console.log("Current proposal state:", uint256(state));

        vm.startBroadcast(voterKey);

        // First, delegate votes to self if not already delegated
        if (token.delegates(vm.addr(voterKey)) == address(0)) {
            console.log("Delegating votes to self...");
            token.delegate(vm.addr(voterKey));
            console.log("Successfully delegated votes to self!");
        } else {
            console.log("Votes already delegated to:", token.delegates(vm.addr(voterKey)));
        }

        uint256 startBlock = block.number;
        console.log("Current block:", startBlock);

        // Roll forward 1 block
        vm.roll(startBlock + 1);

        // Log voting power
        uint256 votingPower = token.getVotes(vm.addr(voterKey));
        console.log("Voting power:", votingPower);

        // If proposal is active, vote
        if (state == IGovernor.ProposalState.Active) {
            console.log("Voting on active proposal...");
            governor.castVote(proposalId, 1);
            console.log("Vote cast successfully!");
        } else {
            console.log("Proposal not in correct state for action");
            console.log("Current state:", uint256(state));
            console.log("State meaning:");
            console.log("0: Pending");
            console.log("1: Active");
            console.log("2: Canceled");
            console.log("3: Defeated");
            console.log("4: Succeeded");
            console.log("5: Queued");
            console.log("6: Expired");
            console.log("7: Executed");
        }

        vm.stopBroadcast();
    }
}
