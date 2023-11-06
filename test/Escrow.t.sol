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

contract EscrowTest is Test {
    Escrow internal escrow;
    Token internal token;
    address internal user1;
    address internal user2;

    function setUp() public {
        user1 = vm.addr(111);
        user2 = vm.addr(222);
        vm.prank(user1);
        token = new Token();
        escrow = new Escrow();
    }

    function testDeposit() public {
        uint256 initBal = token.balanceOf(user1);
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;
        assertGt(initBal, amount);
        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(IERC20(token), user2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(escrow)), amount);
        assertEq(token.balanceOf(user1), initBal - amount);
        assertEq(escrow.withdrawTime(user1, user2), timestamp + 3 days);
    }

    function testDepositFail() public {
        uint256 amount = 1e3 * 1e18;
        vm.startPrank(user1);
        vm.expectRevert();
        escrow.deposit(IERC20(token), user2, amount);
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(IERC20(token), user2, amount);
        vm.stopPrank();

        vm.warp(timestamp + 1 + 3 days);
        vm.prank(user2);
        escrow.withdraw(IERC20(token), user1, amount);

        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(user2), amount);
    }

    function testWithdrawFail() public {
        uint256 amount = 1e3 * 1e18;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        token.approve(address(escrow), amount);
        escrow.deposit(IERC20(token), user2, amount);
        vm.stopPrank();

        vm.expectRevert("Insufficient amount");
        escrow.withdraw(IERC20(token), user1, amount + 1);

        vm.prank(user2);
        vm.expectRevert("Can't withdraw yet");
        escrow.withdraw(IERC20(token), user1, amount);

        vm.warp(4 days);
        vm.expectRevert("Not authorized to withdraw");
        escrow.withdraw(IERC20(token), user1, amount);
    }
}
