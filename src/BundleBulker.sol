// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IInflator.sol";

/**
 * Reinflates a compressed, inflatord 4337 bundle, then submits to EntryPoint.
 * 
 * Lets anyone register a new inflator.
 */
contract BundleBulker {
    address public constant ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    mapping(uint32 => IInflator) public idToInflator;
    mapping(IInflator => uint32) public inflatorToID;

    event InflatorRegistered(uint32 id, IInflator inflator);

    function registerInflator(uint32 inflatorId, IInflator inflator) public {
        require(inflatorId != 0, "Inflator ID cannot be 0");
        require(
            bytes4(inflatorId) != this.registerInflator.selector && bytes4(inflatorId) != this.inflate.selector,
            "Inflator ID cannot clash with other functions"
        );
        require(address(inflator) != address(0), "Inflator address cannot be 0");
        require(address(idToInflator[inflatorId]) == address(0), "Inflator already registered");
        require(inflatorToID[inflator] == 0, "Inflator already registered");

        idToInflator[inflatorId] = inflator;
        inflatorToID[inflator] = inflatorId;

        emit InflatorRegistered(inflatorId, inflator);
    }

    function inflate(bytes calldata compressed) public view returns (UserOperation[] memory ops, address payable beneficiary) {
        uint32 inflatorID = uint32(bytes4(compressed[0:4]));
        IInflator inflator = idToInflator[inflatorID];
        require(address(inflator) != address(0), "Inflator not registered");
        return inflator.inflate(compressed[4:]);
    }

    fallback() external {
        (UserOperation[] memory ops, address payable beneficiary) = inflate(msg.data);
        IEntryPoint(ENTRY_POINT).handleOps(ops, beneficiary);
    }
}
