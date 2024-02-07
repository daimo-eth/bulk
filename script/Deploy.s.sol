// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/BundleBulker.sol";
import "../src/PerOpInflator.sol";
import "../src/DaimoOpInflator.sol";

contract DeployScript is Script {
    function setUp() public {}

    function deploy() public {
        vm.broadcast();
        new BundleBulker{salt:0x7cf7a0f0060e1519d0ee3e12e0ee57890f69d7aa693404299a3a779e90cd7921}();
    }

    function deployPerOpInflator() public {
        vm.startBroadcast();

        // Deploy PerOpInflator
        address payable beneficiary = payable(0x2A6d311394184EeB6Df8FBBF58626B085374Ffe7);
        PerOpInflator pi = new PerOpInflator{salt:0}(msg.sender);
        pi.setBeneficiary(beneficiary);
        vm.stopBroadcast();
    }

    function deployDaimoOpInflator() public {
        vm.startBroadcast();
        // Deploy DaimoOpInflator
        address tokenAddress;
        address paymaster;
        if (block.chainid == 8453) {
            tokenAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base USDC
            paymaster = 0xac5917075b3ED3a6a4516398800f3f64FCf4631E; // DaimoPaymasterV2
        } else if (block.chainid == 84531){
            tokenAddress = 0x1B85deDe8178E18CdE599B4C9d913534553C3dBf; // Base Goerli testUSDC
            paymaster = 0x13f490FafBb206440F25760A10C21A6220017fFa; // Pimlico ERC20 paymaster
        } else if (block.chainid == 84532){
            tokenAddress = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // Base Sepolia Circle USDC
            paymaster = 0xa9E1CCB08053e4f5daBb506718352389C1547462; // DaimoPaymasterV2
        } else {
            revert("Unsupported chain");
        }

        DaimoOpInflator i = new DaimoOpInflator{salt:0}(tokenAddress, msg.sender);
        i.setPaymaster(paymaster);

        vm.stopBroadcast();
    }
}
