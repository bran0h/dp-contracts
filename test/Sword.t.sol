// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwordItem} from "../src/Sword.sol";

contract SwordTest is Test {
    SwordItem public swords;
    address public alice;

    function setUp() public {
        swords = new SwordItem();
        address alice = address(0x1234);
        swords.mintItem(alice, 1, "http://www.example.com");
    }

    function testTransfer() public {
        address bob = address(0x5678);
        vm.startPrank(alice);
        swords.approve(bob, 1);
        swords.transferFrom(alice, bob, 1);
        assertEq(swords.ownerOf(1), bob);
        vm.stopPrank();
    }
}
