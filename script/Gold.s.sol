// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GLDToken} from "../src/Gold.sol";

contract GoldScript is Script {
    GLDToken public gold;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        gold = new GLDToken(10_000);

        vm.stopBroadcast();
    }
}
