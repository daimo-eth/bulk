// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BundleBulker} from "../src/BundleBulker.sol";

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
}
