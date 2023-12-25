// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8;

import "./IOpInflator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "p256-verifier/utils/Base64URL.sol";

interface INameReg {
    function resolveAddr(bytes32 name) external view returns (address);
}

/// Inflates an op containing a Daimo ERC20 transfer.
/// This reduces calldata usage from ~1.5kb to ~400 bytes.
contract DaimoOpInflator is IOpInflator, Ownable {
    address public coinAddr;
    address public paymaster;
    INameReg public nameReg = INameReg(0x72bA7d8E73Fe8Eb666Ea66babC8116a41bFb10e2);
    address public entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    constructor(address _coinAddr, address _owner) {
        coinAddr = _coinAddr;
        transferOwnership(_owner);
    }

    function setPaymaster(address _paymaster) public onlyOwner {
        paymaster = _paymaster;
    }

    function readString(bytes calldata compressed) internal pure returns (bytes32, bytes calldata) {
        uint8 len = uint8(compressed[0]);
        bytes32 str = bytes32(compressed[1:1+len]);
        compressed = compressed[1+len:];
        return (str, compressed);
    }

    function inflate(
        bytes calldata compressed
    ) external view override returns (UserOperation memory op) {
        // Parse userop metadata
        bytes32 fromName;
        bytes32 toName;

        (fromName, compressed) = readString(compressed);
        (toName, compressed) = readString(compressed);

        op.sender = nameReg.resolveAddr(fromName);
        op.nonce = uint256(uint128(bytes16(compressed[0:16]))) << 64;
        op.initCode = "";
        op.callGasLimit = uint256(300000);
        op.verificationGasLimit = uint256(700000);
        op.preVerificationGas = uint256(uint32(bytes4(compressed[16:20])));
        op.maxFeePerGas = uint256(uint48(bytes6(compressed[20:26])));
        op.maxPriorityFeePerGas = uint256(uint48(bytes6(compressed[26:32])));

        // Add calldata
        address recipientAddr = nameReg.resolveAddr(toName);
        bytes6 amount = bytes6(compressed[32:38]);
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
        compressed = compressed[38:];
        uint8 version = uint8(compressed[0]);
        require(version == 1, "Unsupported version");
        bytes6 validUntil = bytes6(compressed[1:7]);
        uint8 keySlot = uint8(compressed[7]);

        Signature memory sig;
        sig.authenticatorData = abi.encodePacked(bytes32(0), hex"0500000000");
        sig.responseTypeLocation = 1;
        sig.challengeLocation = 23;
        sig.r = uint256(bytes32(compressed[8:40]));
        sig.s = uint256(bytes32(compressed[40:72]));


        // Finally, add the paymaster + ticket signature for sponsored gas
        op.paymasterAndData = abi.encodePacked(
            paymaster,
            compressed[72:] // paymaster data, if required
        );

        // Template WebAuthn signature
        // Challenge is always 52 bytes: 39 bytes (1 byte version + 6 byte validUntil + 32 byte opHash) * 8/6 for Base64
        bytes32 opDataHash = keccak256(packOpData(op));
        bytes32 userOpHash = keccak256(abi.encode(opDataHash, entryPoint, block.chainid));

        string memory challenge = Base64URL.encode(abi.encodePacked(version, validUntil, userOpHash));
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

        return op;
    }

    // Copied from UserOperation.sol
    // The version there only operates on UserOperation calldata
    function packOpData(UserOperation memory userOp) internal pure returns (bytes memory ret) {
        address sender = userOp.sender;
        // require(sender == address(0x8bFfa71A959AF0b15C6eaa10d244d80BF23cb6A2));
        uint256 nonce = userOp.nonce;
        // require(nonce == 1964309238010514598139960553805611309456889087397726257152);
        bytes32 hashInitCode = keccak256(userOp.initCode);
        // require(hashInitCode == keccak256(hex""));
        bytes32 hashCallData = keccak256(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        // require(callGasLimit == 300000);
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        // require(verificationGasLimit == 700000);
        uint256 preVerificationGas = userOp.preVerificationGas;
        // require(preVerificationGas == 8078499);
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        // require(maxFeePerGas == 1000050);
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        // require(maxPriorityFeePerGas == 1000000);
        bytes32 hashPaymasterAndData = keccak256(userOp.paymasterAndData);
        // require(hashPaymasterAndData == keccak256(hex"99d720cd5a04c16dc5377638e3f6d609c895714f"));

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
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
