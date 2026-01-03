// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuthManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external returns (bool);
}

contract SecureVault {
    IAuthManager public immutable authManager;
    
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount, bytes32 indexed nonce);

    constructor(address _authManager) {
        authManager = IAuthManager(_authManager);
    }

    // Accept incoming funds
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(
        address payable _recipient,
        uint256 _amount,
        bytes32 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external {
        require(address(this).balance >= _amount, "Insufficient vault balance");

        // CALL THE MANAGER: Validate permission
        bool authorized = authManager.verifyAuthorization(
            address(this),
            _recipient,
            _amount,
            _nonce,
            _deadline,
            _signature
        );

        require(authorized, "Authorization failed");

        // If authorized, transfer funds
        emit Withdrawal(_recipient, _amount, _nonce);
        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}