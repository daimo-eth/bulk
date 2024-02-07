// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";

import {IInflator} from "../src/IInflator.sol";
import {DaimoOpInflator} from "../src/DaimoOpInflator.sol";


contract DummyNameReg {
    function resolveAddr(bytes32 name) external pure returns (address) {
        if (name== bytes32(bytes("bob"))) {
            return address(0x8bFfa71A959AF0b15C6eaa10d244d80BF23cb6A2);
        } else if (name == bytes32(bytes("blob"))) {
            return address(0xA1B349c566C44769888948aDC061ABCdB54497F7);
        } else {
            return address(0);
        }
    }
}

contract DaimoOpInflatorTest is Test {
    function setUp() public {
        DummyNameReg nameReg = new DummyNameReg();
        vm.etch(address(0x4430A644B215a187a3daa5b114fA3f3d9DeBc17D), address(nameReg).code);
        vm.chainId(8453);
    }

    function test_DaimoOpInflator() public {
        address payable alice = payable(address(0x123));
        DaimoOpInflator d = new DaimoOpInflator(
            address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913),
            alice
        );
        vm.startPrank(alice);
        d.setPaymaster(address(0x99D720cd5A04c16Dc5377638e3f6D609c895714F));
        vm.stopPrank();

        bytes memory compressed = abi.encodePacked(
            hex"03626F62", // sender
            hex"04626C6F62", // to
            hex"501c58693b65f1374631a2fca7bb7dc6", // nonce
            hex"007b44a3", // preVerificationGas
            hex"0000000f4272", // maxFeePerGas
            hex"0000000f4240", // maxPriorityFeePerGas
            hex"0000000f4240", // amount
            hex"0100006553c75f00", // sig version, validUntil, keySlot
            hex"ce1a2a89ec9d3cecd1e9fd65808d85702d7f8681d42ce8f0982363a362b87bd5", // sig r
            hex"498c72f497f9d27ae895c6d2c10a73e85b73d258371d2322c80ca5bfad242f5f" // sig s
        );

        // Length paymaster ticket sig: 119 bytes
        assertEq(compressed.length, 119);

        UserOperation memory op = d.inflate(compressed);

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
            hex"99d720cd5a04c16dc5377638e3f6d609c895714f"
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