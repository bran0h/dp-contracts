// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/lib/GameRegistryGovernor.sol";

contract CheckProposal is Script {
    function run() external view {
        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");
        console.log("Proposal ID:", proposalId);

        GameRegistryGovernor governor = GameRegistryGovernor(payable(governorAddress));

        // Get current state
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
