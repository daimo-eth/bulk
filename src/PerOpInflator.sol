// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IInflator.sol";
import "./IOpInflator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";

/// Inflates a bundle containing n ops, each with their own inflator specified.
contract PerOpInflator is IInflator, Ownable {
    address payable public beneficiary;

    mapping(uint32 => IOpInflator) public idToInflator;
    mapping(IOpInflator => uint32) public inflatorToID;

    event OpInflatorRegistered(uint32 id, IOpInflator inflator);

    function registerOpInflator(uint32 inflatorId, IOpInflator inflator) public {
        require(inflatorId != 0, "Inflator ID cannot be 0");
        require(address(inflator) != address(0), "Inflator address cannot be 0");
        require(address(idToInflator[inflatorId]) == address(0), "Inflator already registered");
        require(inflatorToID[inflator] == 0, "Inflator already registered");

        idToInflator[inflatorId] = inflator;
        inflatorToID[inflator] = inflatorId;

        emit OpInflatorRegistered(inflatorId, inflator);
    }

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function inflate(
        bytes calldata compressed
    ) external view override returns (UserOperation[] memory, address payable) {
        uint256 numOps = uint256(uint8(bytes1(compressed[0:1])));
        UserOperation[] memory ops = new UserOperation[](numOps);
        uint256 offset = 1;
        for (uint256 i = 0; i < numOps; i++) {
            uint32 inflatorID = uint32(bytes4(compressed[offset:offset+4]));
            uint16 opSize = uint16(bytes2(compressed[offset+4:offset+6]));
            offset += 6;
            
            IOpInflator inflator = idToInflator[inflatorID];
            require(address(inflator) != address(0), "Bad inflator ID");
            ops[i] = inflator.inflate(compressed[offset:offset+opSize]);
            offset += opSize;
        }
        require(offset == compressed.length, "Wrong compressed length");

        return (ops, beneficiary);
    }
}
