// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GLDToken} from "../src/Gold.sol";

contract GoldTest is Test {
    GLDToken public gold;

    function setUp() public {
        gold = new GLDToken(10_000);
    }

    // Test balance of the contract creator
    function testBalance() public {
        assertEq(gold.balanceOf(address(this)), 10_000);
    }

    // Test total supply
    function testTotalSupply() public {
        assertEq(gold.totalSupply(), 10_000);
    }

    // Test name
    function testName() public {
        assertEq(gold.name(), "Gold");
    }

    // Test symbol
    function testSymbol() public {
        assertEq(gold.symbol(), "GLD");
    }

    // Test transfer
    function testTransfer() public {
        // Create a new account
        address alice = address(0x1234);
        gold.transfer(alice, 100);
        assertEq(gold.balanceOf(alice), 100);
        assertEq(gold.balanceOf(address(this)), 9_900);
    }
}
