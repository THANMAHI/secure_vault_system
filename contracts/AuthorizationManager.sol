// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorizationManager is EIP712, Ownable {
    // Tracks if a specific authorization ID (nonce) has been used
    mapping(bytes32 => bool) public isNonceConsumed;

    // Defines the structure of the data we are signing
    bytes32 private constant AUTHORIZATION_TYPEHASH = 
        keccak256("Authorization(address vault,address recipient,uint256 amount,bytes32 nonce,uint256 deadline)");

    event AuthorizationConsumed(bytes32 indexed nonce, address indexed vault, address indexed recipient);

    constructor() EIP712("SecureVaultAuth", "1") Ownable(msg.sender) {}

    function verifyAuthorization(
        address _vault,
        address _recipient,
        uint256 _amount,
        bytes32 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external returns (bool) {
        // 1. Check if expired
        require(block.timestamp <= _deadline, "Authorization expired");

        // 2. Check replay protection (has this nonce been used?)
        require(!isNonceConsumed[_nonce], "Authorization already used");

        // 3. Reconstruct the signed data digest
        bytes32 structHash = keccak256(abi.encode(
            AUTHORIZATION_TYPEHASH,
            _vault,
            _recipient,
            _amount,
            _nonce,
            _deadline
        ));
        bytes32 digest = _hashTypedDataV4(structHash);

        // 4. Recover the signer address from signature
        address signer = ECDSA.recover(digest, _signature);

        // 5. Verify the signer is the Owner (the off-chain system)
        require(signer == owner(), "Invalid signature source");

        // 6. Mark nonce as consumed PERMANENTLY
        isNonceConsumed[_nonce] = true;

        emit AuthorizationConsumed(_nonce, _vault, _recipient);
        return true;
    }
}