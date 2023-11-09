// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {ERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Mock Token", "MT") {
        _mint(msg.sender, 1e4 * 1e18);
    }
}

contract FeeTokenOnTransfer is ERC20 {
    constructor() ERC20("Mock Fee Token Transfer", "MFTT") {
        _mint(msg.sender, 1e4 * 1e18);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount - 1);
    }
}

contract FeeTokenOnTransferFrom is ERC20 {
    constructor() ERC20("Mock Fee Token Transfer From", "MFTTF") {
        _mint(msg.sender, 1e4 * 1e18);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, amount - 1);
    }
}

contract EscrowTest is Test {
    Escrow internal escrow;
    Token internal token;
    FeeTokenOnTransfer internal feeTokenOnTransfer;
    FeeTokenOnTransferFrom internal feeTokenOnTransferFrom;
    address internal user1;
    address internal user2;

    function setUp() public {
        user1 = vm.addr(111);
        user2 = vm.addr(222);
        vm.startPrank(user1);
        token = new Token();
        feeTokenOnTransfer = new FeeTokenOnTransfer();
        feeTokenOnTransferFrom = new FeeTokenOnTransferFrom();
        vm.stopPrank();
        escrow = new Escrow();
    }

    function testDeposit() public {
        uint256 initBal = token.balanceOf(user1);
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;
        assertGt(initBal, amount);
        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(address(token), user2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(escrow)), amount);
        assertEq(token.balanceOf(user1), initBal - amount);
        assertEq(escrow.withdrawTime(address(token), user1, user2), timestamp + 3 days);
    }

    function testDepositFail() public {
        uint256 amount = 1e3 * 1e18;
        vm.startPrank(user1);
        vm.expectRevert();
        escrow.deposit(address(token), user2, amount);
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(address(token), user2, amount);
        vm.stopPrank();

        vm.warp(timestamp + 1 + 3 days);
        vm.prank(user2);
        escrow.withdraw(address(token), user1, amount);

        assertEq(escrow.accountBalance(address(token), user1), 0);
        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(user2), amount);
    }

    function testWithdrawFail() public {
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(address(token), user2, amount);
        vm.stopPrank();

        vm.expectRevert("Insufficient amount");
        escrow.withdraw(address(token), user1, amount + 1);

        vm.prank(user2);
        vm.expectRevert("Can't withdraw yet");
        escrow.withdraw(address(token), user1, amount);

        vm.warp(timestamp + 3 days);
        vm.prank(user2);
        vm.expectRevert("Can't withdraw yet");
        escrow.withdraw(address(token), user1, amount);

        vm.warp(timestamp + 1 + 3 days);
        vm.expectRevert("Not authorized to withdraw");
        escrow.withdraw(address(token), user1, amount);
    }

    function testWithdrawFailDepositAssertion() public {
        uint256 amount = 1e3 * 1e18;

        vm.startPrank(user1);
        feeTokenOnTransferFrom.approve(address(escrow), amount);
        vm.expectRevert();
        escrow.deposit(address(feeTokenOnTransferFrom), user2, amount);
        vm.stopPrank();
    }

    function testWithdrawFailWithdrawAssertion() public {
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        feeTokenOnTransfer.approve(address(escrow), amount);
        escrow.deposit(address(feeTokenOnTransfer), user2, amount);
        vm.stopPrank();

        vm.warp(timestamp + 1 + 3 days);
        vm.prank(user2);
        vm.expectRevert();
        escrow.withdraw(address(feeTokenOnTransfer), user1, amount);
    }
}
