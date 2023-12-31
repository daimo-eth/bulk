// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";

import {BundleBulker} from "../src/BundleBulker.sol";
import {IInflator} from "../src/IInflator.sol";
import {DaimoTransferInflator} from "../src/DaimoTransferInflator.sol";

contract BundleBulkerTest is Test {
    BundleBulker public b;

    function setUp() public {
        b = new BundleBulker();
    }

    function test_AddInflator() public {
        IInflator tango = IInflator(address(0x123));
        IInflator foxtrot = IInflator(address(0x234));

        b.registerInflator(1, tango);
        assertEq(address(b.idToInflator(1)), address(tango));
        assertEq(b.inflatorToID(tango), 1);

        vm.expectRevert("Inflator ID cannot be 0");
        b.registerInflator(0, tango);
        vm.expectRevert("Inflator address cannot be 0");
        b.registerInflator(2, IInflator(address(0)));
        vm.expectRevert("Inflator already registered");
        b.registerInflator(1, foxtrot);
        vm.expectRevert("Inflator already registered");
        b.registerInflator(2, tango);

        b.registerInflator(2, foxtrot);
        assertEq(address(b.idToInflator(2)), address(foxtrot));
        assertEq(b.inflatorToID(foxtrot), 2);
    }

    function test_Inflate() public {
        DummyInflator d = new DummyInflator();
        b.registerInflator(77, d);

        bytes memory compressed = abi.encodePacked(uint32(77), address(0x999));
        (UserOperation[] memory ops, address payable beneficiary) = b.inflate(
            compressed
        );
        assertEq(beneficiary, payable(address(0x999)));
        assertEq(ops.length, 0);
    }

    function test_DaimoTransferInflator() public {
        address payable alice = payable(
            0x43370330BE39D388f6219d8241dC1f76Fb9DF268
        );
        DaimoTransferInflator t = new DaimoTransferInflator(
            address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913),
            alice
        );
        vm.startPrank(alice);
        t.setBeneficiary(alice);
        t.setPaymaster(address(0x6f0F82fAFac7B5D8C269B02d408F094bAC6CF877));
        vm.stopPrank();

        bytes memory compressed = abi.encodePacked(
            hex"8bffa71a959af0b15c6eaa10d244d80bf23cb6a2", // sender
            hex"501c58693b65f1374631a2fca7bb7dc6", // nonce
            hex"007b44a3", // preVerificationGas
            hex"0000000f4272", // maxFeePerGas
            hex"0000000f4240", // maxPriorityFeePerGas
            hex"a1b349c566c44769888948adc061abcdb54497f7", // to
            hex"0000000f4240", // amount
            hex"0100006553c75f00", // sig version, validUntil, keySlot
            hex"ce1a2a89ec9d3cecd1e9fd65808d85702d7f8681d42ce8f0982363a362b87bd5", // sig r
            hex"498c72f497f9d27ae895c6d2c10a73e85b73d258371d2322c80ca5bfad242f5f", // sig s
            hex"415141415A5650485830567A705463726D35665A6846505F566369545433584D57484832624E7A6A6435346531774E354D32696F" // authenticatorChallenge

            // Below is OPTIONAL paymaster data. Most paymasters don't need this.
            // Even sponsoring paymasters are possible without an extra signature with tricks.
            hex"99", // paymaster sig v
            hex"7777777777777777777777777777777777777777777777777777777777777777", // paymaster sig r
            hex"8888888888888888888888888888888888888888888888888888888888888888", // paymaster sig s
            hex"00006553c999" // paymaster ticket validUntil
        );

        // Length paymaster ticket sig: 273 bytes
        // LENGTH WITH CORRECTLY OPTIMIZED PAYMASTER: 202 bytes
        assertEq(compressed.length, 273);

        (UserOperation[] memory ops, address payable beneficiary) = t.inflate(
            compressed
        );

        // Verify inflated 4337 bundle
        assertEq(beneficiary, alice);
        assertEq(ops.length, 1);

        // Verify the one userop in the bundle
        UserOperation memory op = ops[0];
        assertEq(
            op.sender,
            address(0x8bFfa71A959AF0b15C6eaa10d244d80BF23cb6A2)
        );
        assertEq(op.nonce, 0x501c58693b65f1374631a2fca7bb7dc60000000000000000);
        assertEq(op.initCode, "");
        assertEq(op.callData, 
            hex"34fcd5be" // executeBatch
            hex"0000000000000000000000000000000000000000000000000000000000000020"
            hex"0000000000000000000000000000000000000000000000000000000000000001"
            hex"0000000000000000000000000000000000000000000000000000000000000020"
            hex"000000000000000000000000833589fcd6edb6e08f4c7c32d4f71b54bda02913"
            hex"0000000000000000000000000000000000000000000000000000000000000000"
            hex"0000000000000000000000000000000000000000000000000000000000000060"
            hex"0000000000000000000000000000000000000000000000000000000000000044"
            hex"a9059cbb" // transfer
            hex"000000000000000000000000a1b349c566c44769888948adc061abcdb54497f7"
            hex"00000000000000000000000000000000000000000000000000000000000f4240"
            hex"00000000000000000000000000000000000000000000000000000000"
        );
        assertEq(op.callGasLimit, 300000);
        assertEq(op.verificationGasLimit, 700000);
        assertEq(op.preVerificationGas, 8078499);
        assertEq(op.maxFeePerGas, 1000050);
        assertEq(op.maxPriorityFeePerGas, 1000000);
        assertEq(
            op.paymasterAndData,
            hex"6f0F82fAFac7B5D8C269B02d408F094bAC6CF877"
            hex"99"
            hex"7777777777777777777777777777777777777777777777777777777777777777"
            hex"8888888888888888888888888888888888888888888888888888888888888888"
            hex"00006553c999"
        );
        assertEq(
            op.signature,
            abi.encodePacked(
                hex"01"
                hex"00006553c75f"
                hex"00"
                hex"0000000000000000000000000000000000000000000000000000000000000020"
                hex"00000000000000000000000000000000000000000000000000000000000000c0"
                hex"0000000000000000000000000000000000000000000000000000000000000120"
                hex"0000000000000000000000000000000000000000000000000000000000000017"
                hex"0000000000000000000000000000000000000000000000000000000000000001"
                hex"ce1a2a89ec9d3cecd1e9fd65808d85702d7f8681d42ce8f0982363a362b87bd5"
                hex"498c72f497f9d27ae895c6d2c10a73e85b73d258371d2322c80ca5bfad242f5f"
                hex"0000000000000000000000000000000000000000000000000000000000000025"
                hex"0000000000000000000000000000000000000000000000000000000000000000"
                hex"0500000000000000000000000000000000000000000000000000000000000000"
                hex"000000000000000000000000000000000000000000000000000000000000005a",
                '{"type":"webauthn.get","challenge":"AQAAZVPHX0VzpTcrm5fZhFP_VciTT3XMWHH2bNzjd54e1wN5M2io"}',
                hex"000000000000"
            )
        );
    }
}

contract DummyInflator is IInflator {
    function inflate(bytes calldata compressed)
        external
        override
        pure
        returns (UserOperation[] memory ops, address payable beneficiary)
    {
        assert(compressed.length == 20);
        ops = new UserOperation[](0);
        beneficiary = payable(address(bytes20(compressed[0:20])));
    }
}