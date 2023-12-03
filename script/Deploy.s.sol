// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/BundleBulker.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        new BundleBulker{salt:0}();
    }
}
