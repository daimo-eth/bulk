// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IInflator.sol";

/**
 * Reinflates a compressed, inflatord 4337 bundle, then submits to EntryPoint.
 * 
 * Lets anyone register a new inflator.
 */
contract BundleBulker {
    // IEntryPoint public constant entryPoint =
    //     IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    mapping(uint32 => address) public idToInflator;
    mapping(address => uint32) public inflatorToID;

    function registerInflator(uint32 inflatorId, address inflator) public {
        require(inflatorId != 0, "Inflator ID cannot be 0");
        require(inflator != address(0), "Inflator address cannot be 0");
        require(idToInflator[inflatorId] == address(0), "Inflator already registered");
        require(inflatorToID[inflator] == 0, "Inflator already registered");

        idToInflator[inflatorId] = inflator;
        inflatorToID[inflator] = inflatorId;
    }

    function bulk(bytes calldata compressed) public view returns (bytes memory inflated) {
        uint32 inflatorID = uint32(bytes4(compressed[0:4]));
        address inflator = idToInflator[inflatorID];
        require(inflator != address(0), "Inflator not registered");
        return (IInflator(inflator).inflate(compressed));
    }

    // function submit(bytes calldata compressed) public {
    //     uint32 inflatorID = uint32(bytes4(compressed[0:4]));
    //     address inflator = idToInflator[inflatorID];
    //     require(inflator != address(0), "Inflator not registered");
    //     bytes memory inflated = IInflator(inflator).inflate(compressed);
    //     entryPoint.submit(inflated);
    // }
    
}
