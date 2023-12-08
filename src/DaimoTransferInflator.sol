// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IInflator.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";

/// Inflates a bundle containing a single Daimo USDC transfer.
/// This reduces calldata usage from ~1.5kb to ~400 bytes.
contract DaimoTransferInflator is IInflator, Ownable {
    address public coinAddr;
    address payable public beneficiary;
    address public paymaster;

    constructor(address _coinAddr, address _owner) {
        coinAddr = _coinAddr;
        transferOwnership(_owner);
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setPaymaster(address _paymaster) public onlyOwner {
        paymaster = _paymaster;
    }

    function inflate(
        bytes calldata compressed
    ) external view override returns (UserOperation[] memory, address payable) {
        // Parse userop metadata
        UserOperation memory op;
        op.sender = address(uint160(bytes20(compressed[0:20])));
        op.nonce = uint256(uint128(bytes16(compressed[20:36]))) << 64;
        op.initCode = "";
        op.callGasLimit = uint256(300000);
        op.verificationGasLimit = uint256(700000);
        op.preVerificationGas = uint256(uint32(bytes4(compressed[36:40])));
        op.maxFeePerGas = uint256(uint48(bytes6(compressed[40:46])));
        op.maxPriorityFeePerGas = uint256(uint48(bytes6(compressed[46:52])));

        // Add calldata
        bytes20 recipientAddr = bytes20(compressed[52:72]);
        bytes6 amount = bytes6(compressed[72:78]);
        op.callData = abi.encodePacked(
            hex"34fcd5be", // executeBatch
            uint256(32), // offset calls
            uint256(1), // len(calls)
            uint256(32), // offset calls[0]
            hex"000000000000000000000000", // offset to token
            coinAddr, // eg Base USDC
            uint256(0), // value
            uint256(0x60), // offset calls[0].data
            uint256(0x44), // len(calls[0].data)
            hex"a9059cbb", // transfer(address,uint256)
            hex"000000000000000000000000", // offset to address
            recipientAddr,
            bytes26(0), // offset to amount
            uint48(amount),
            bytes28(0) // padding
        );

        // Decompress WebAuthn signature
        bytes calldata compressedSig = compressed[78:202];

        uint8 version = uint8(compressedSig[0]);
        require(version == 1, "Unsupported version");
        bytes6 validUntil = bytes6(compressedSig[1:7]);
        uint8 keySlot = uint8(compressedSig[7]);

        Signature memory sig;
        sig
            .authenticatorData = hex"00000000000000000000000000000000000000000000000000000000000000000500000000";

        sig.responseTypeLocation = 1;
        sig.challengeLocation = 23;
        sig.r = uint256(bytes32(compressedSig[8:40]));
        sig.s = uint256(bytes32(compressedSig[40:72]));

        // Challenge is always 52 bytes: 39 bytes (1 byte version + 6 byte validUntil + 32 byte opHash) * 8/6 for Base64
        // We could save 20 bytes by passing just the opHash, but unclear if worth the extra complexity.
        bytes calldata challenge = compressedSig[72:];
        sig.clientDataJSON = string(
            abi.encodePacked(
                '{"type":"webauthn.get","challenge":"',
                challenge,
                '"}'
            )
        );
        op.signature = abi.encodePacked(
            version,
            validUntil,
            keySlot,
            abi.encode(sig)
        );


        // Finally, add the paymaster + ticket signature for sponsored gas
        op.paymasterAndData = abi.encodePacked(
            paymaster,
            compressed[202:] // paymaster data, if required
        );

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        return (ops, beneficiary);
    }
}

struct Signature {
    bytes authenticatorData;
    string clientDataJSON;
    uint256 challengeLocation;
    uint256 responseTypeLocation;
    uint256 r;
    uint256 s;
}
