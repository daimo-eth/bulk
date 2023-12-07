// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/BundleBulker.sol";
import "../src/DaimoTransferInflator.sol";

contract DeployScript is Script {
    function setUp() public {}

    function deploy() public {
        vm.broadcast();
        new BundleBulker{salt:0}();
    }

    function deployDaimoTransferInflator() public {
        address tokenAddress;
        if (block.chainid == 8453) {
            tokenAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base USDC
        } else if (block.chainid == 84531){
            tokenAddress = 0x1B85deDe8178E18CdE599B4C9d913534553C3dBf; // Base Goerli testUSDC
        } else {
            revert("Unsupported chain");
        }

        vm.broadcast();
        new DaimoTransferInflator{salt:0}(tokenAddress);
    }
}
