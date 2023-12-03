// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

interface IInflator {
    function inflate(bytes calldata compressed) external view returns (bytes memory inflated);
}