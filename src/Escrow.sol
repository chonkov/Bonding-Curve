// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20, ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// NOTE:

// Problem 1:

// Because some popular tokens like Tether USD (USDT) are not actually ERC20 tokens, their behaviour may lead to potential bugs - for example, if in the
// Escrow contract, a bool is expected as a return value and checked whether it is true or not, this can lead to a DoS attack, if` the token, that is
// trying to be transferred from, is USDT.

// Problem 2:

// If the token is an ERC777, when withdrawing, the '_callTokensReceived' will be always called, therefore giving control to the receiving contract
// The same could happen if the token is ERC1363 compliant, but only if the IERC1363 methods are being called (transferAndCall and transferFromAndCall).
// This means that, because the openzeppelin ERC1363 does not override the transfer and transferFrom methods, like with the ERC777, no control is being
// transfered to a potentially malicious contract. A solution might be to whitelist certain well-established ERC777, ERC1363 contracts. ERC20 can be used
// always due to its simplicity, but 2 txs would be required - one for approving and another for transfering the approved amount to the 'Escrow' contract.

// Problem 3:

// The token might implement a fee in its contract on every single transfer. This means that if 'X' amount of tokens are transferred to the Escrow
// contract, because of the fee, only 99 / 100 * 'X' of the total value will be actually transferred, therefore resulting in errors in the state of the
// Escrow contract and the one of the token.

// Deposit:
// Implement hooks before and after the 'safeTransferFrom' method

/// @title Escrow
/// @author Georgi
/// @notice Escrow contract that accepts ARBITRARY ERC20 tokens
contract Escrow {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) public accountBalance;
    mapping(address => mapping(address => mapping(address => uint256))) public withdrawTime;

    event Deposit(address indexed, address indexed, uint256);
    event Withdraw(address indexed, address indexed, uint256);

    /// @notice Deposit function accepting ERC20 tokens
    /// @param token address An arbitrary token address used for making a deposit
    /// @param to address The address to which the tokens are to be transfered
    /// @param amount uint256 The amount of tokens transferred
    function deposit(address token, address to, uint256 amount) external {
        uint256 balBefore = IERC20(token).balanceOf(address(this));

        accountBalance[token][msg.sender] += amount;
        withdrawTime[token][msg.sender][to] = block.timestamp + 3 days;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount); // A fee could potenitally be paid
        uint256 balAfter = IERC20(token).balanceOf(address(this));
        assert(balAfter == balBefore + amount); // Check if balances match before and after `safeTransfer` was called due to fee implementation

        emit Deposit(msg.sender, to, amount);
    }

    /// @notice Withdraw function
    /// @param token address An arbitrary token address used for transfering value
    /// @param from address The address to which the tokens are to be transfered
    /// @param amount uint256 The amount of tokens transferred
    function withdraw(address token, address from, uint256 amount) external {
        uint256 _withdrawTime = withdrawTime[token][from][msg.sender];
        uint256 balBefore = IERC20(token).balanceOf(address(this));

        require(accountBalance[token][from] >= amount, "Insufficient amount");
        require(block.timestamp > _withdrawTime, "Can't withdraw yet");
        require(_withdrawTime > 0, "Not authorized to withdraw"); // If `_withdrawTime` == 0, then the caller can't withdraw because no deposit has been made

        unchecked {
            accountBalance[token][from] -= amount;
        }

        IERC20(token).safeTransfer(msg.sender, amount); // another fee would be paid if for the example the token is Tether
        uint256 balAfter = IERC20(token).balanceOf(address(this));
        assert(balAfter == balBefore - amount); // Check if balances match before and after `safeTransfer` was called due to fee implementation

        emit Withdraw(from, msg.sender, amount);
    }
}
