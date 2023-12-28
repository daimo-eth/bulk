// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UserOperation} from "account-abstraction/interfaces/IEntryPoint.sol";

import {PerOpInflator} from "../src/PerOpInflator.sol";
import {IInflator} from "../src/IInflator.sol";
import {IOpInflator} from "../src/IOpInflator.sol";


contract DummyOpInflator is IOpInflator {
    function inflate(
        bytes calldata compressed
    ) external pure override returns (UserOperation memory) {
        require(compressed.length == 4, "Wrong compressed length");
        require(uint32(bytes4(compressed[0:4])) == 0x12345678, "Wrong compressed data");
        UserOperation memory op;
        return op;
    }
}

contract PerOpInflatorTest is Test {
    function setUp() public {
    }

    function test_PerOpInflator() public {
        address payable alice = payable(address(0x123));
        PerOpInflator poi = new PerOpInflator(address(this));
        poi.setBeneficiary(alice);
        DummyOpInflator doi = new DummyOpInflator();
        poi.registerOpInflator(256, doi);


        bytes memory compressed = abi.encodePacked(
            hex"01", // 1 op
            hex"00000100", // inflator 100
            hex"0004", // op size
            hex"12345678" // op
        );

        (UserOperation[] memory ops, address beneficiary) = poi.inflate(compressed);

        assertEq(ops.length, 1);
        assertEq(beneficiary, alice);
    }
}