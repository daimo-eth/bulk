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
        address payable beneficiary = payable(0x2A6d311394184EeB6Df8FBBF58626B085374Ffe7);
        address paymaster;
        if (block.chainid == 8453) {
            tokenAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base USDC
            paymaster = 0xedb395b8BD78788A57e3C8eD9b748f9CC29C2864; // Daimo Sub Paymaster (uses Metapaymaster)
        } else if (block.chainid == 84531){
            tokenAddress = 0x1B85deDe8178E18CdE599B4C9d913534553C3dBf; // Base Goerli testUSDC
            paymaster = 0x6f0F82fAFac7B5D8C269B02d408F094bAC6CF877; // DaimoPaymaster
        } else {
            revert("Unsupported chain");
        }

        vm.startBroadcast();
        DaimoTransferInflator i = new DaimoTransferInflator{salt:0}(tokenAddress, msg.sender);
        i.setBeneficiary(beneficiary);
        i.setPaymaster(paymaster);
        vm.stopBroadcast();
    }
}
