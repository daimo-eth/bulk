// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IInflator.sol";
import "inflate-sol/InflateLib.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import {Test, console2} from "forge-std/Test.sol";

/// Inflates a generic bundle compressed with DEFLATE
/// This reduces calldata size by ~72% and calldata cost by ~37%
/// (due to calldata 0-bytes being cheaper than non-0-bytes)
contract DeflateInflator is IInflator {
    error InflateLibError(InflateLib.ErrorCode errorCode);

    function inflate(
        bytes calldata compressed
    ) external view override returns (UserOperation[] memory, address payable) {
        (InflateLib.ErrorCode errorCode, bytes memory decompressed) = InflateLib
            .puff(compressed[3:], uint24(bytes3(compressed[0:3])));

        if (errorCode != InflateLib.ErrorCode.ERR_NONE) {
            revert InflateLibError(errorCode);
        }

        UserOperation[] memory ops = abi.decode(
            abi.encodePacked(uint256(0x20), decompressed),
            (UserOperation[])
        );

        return (ops, payable(tx.origin));
    }
}
