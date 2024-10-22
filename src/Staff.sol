// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GameItem.sol";

contract StaffItem is GameItem {
    constructor() GameItem("Sword", "SWD") Ownable(msg.sender) {}

    // Define the initial attributes for a sword
    function initializeAttributes(uint256 tokenId) internal override {
        _setAttribute(tokenId, "intelect", 100);
        _setAttribute(tokenId, "durability", 250);

        // Lock the attributes after initialization, so they can't be modified
        _lockAttribute(tokenId, "intelect");
        _lockAttribute(tokenId, "durability");
    }
}
