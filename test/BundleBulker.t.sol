// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";

import {BundleBulker} from "../src/BundleBulker.sol";
import {DaimoTransferInflator} from "../src/DaimoTransferInflator.sol";

contract BundleBulkerTest is Test {
    BundleBulker public b;

    function setUp() public {
        b = new BundleBulker();
    }

    function test_AddInflator() public {
        address tango = address(0x123);
        address foxtrot = address(0x234);

        b.registerInflator(1, tango);
        assertEq(b.idToInflator(1), tango);
        assertEq(b.inflatorToID(tango), 1);

        vm.expectRevert("Inflator ID cannot be 0");
        b.registerInflator(0, tango);
        vm.expectRevert("Inflator address cannot be 0");
        b.registerInflator(2, address(0));
        vm.expectRevert("Inflator already registered");
        b.registerInflator(1, foxtrot);
        vm.expectRevert("Inflator already registered");
        b.registerInflator(2, tango);

        b.registerInflator(2, foxtrot);
        assertEq(b.idToInflator(2), foxtrot);
        assertEq(b.inflatorToID(foxtrot), 2);
    }

    function test_Inflate() public {
        address payable alice = payable(0x43370330BE39D388f6219d8241dC1f76Fb9DF268);
        DaimoTransferInflator t = new DaimoTransferInflator(
            address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
        );
        t.setBeneficiary(alice);

        bytes memory compressed = abi.encodePacked(
            hex"8bffa71a959af0b15c6eaa10d244d80bf23cb6a2", // sender
            hex"501c58693b65f1374631a2fca7bb7dc6", // nonce
            hex"007b44a3", // preVerificationGas
            hex"0000000f4272", // maxFeePerGas
            hex"0000000f4240", // maxPriorityFeePerGas
            hex"a1b349c566c44769888948adc061abcdb54497f7", // to
            hex"0000000f4240", // amount
            hex"7777777777777777777777777777777777777777777777777777777777777777", // paymaster sig r
            hex"8888888888888888888888888888888888888888888888888888888888888888", // paymaster sig s
            hex"99", // paymaster sig v
            hex"0100006553c75f00", // sig version, validUntil, keySlot
            hex"ce1a2a89ec9d3cecd1e9fd65808d85702d7f8681d42ce8f0982363a362b87bd5", // sig r
            hex"498c72f497f9d27ae895c6d2c10a73e85b73d258371d2322c80ca5bfad242f5f", // sig s
            hex"415141415A5650485830567A705463726D35665A6846505F566369545433584D57484832624E7A6A6435346531774E354D32696F" // authenticatorChallenge
        );
        assertEq(compressed.length, 267);

        (UserOperation[] memory ops, address payable beneficiary) = t.inflate(
            compressed
        );

        assertEq(beneficiary, alice);
        assertEq(ops.length, 1);
        UserOperation memory op = ops[0];
        assertEq(
            op.sender,
            address(0x8bFfa71A959AF0b15C6eaa10d244d80BF23cb6A2)
        );
        assertEq(op.nonce, 0x501c58693b65f1374631a2fca7bb7dc60000000000000000);
        assertEq(op.preVerificationGas, 8078499);
        assertEq(op.maxFeePerGas, 1000050);
        assertEq(op.maxPriorityFeePerGas, 1000000);

    }
}
