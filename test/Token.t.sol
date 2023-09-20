// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenSetup is Test {
    Token internal token;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal bannedUser;

    function setUp() public virtual {
        owner = vm.addr(123);

        user1 = vm.addr(456);

        user2 = vm.addr(789);

        bannedUser = vm.addr(555);

        vm.prank(owner);
        token = new Token("Token", "TKN");
    }
}

contract TokenTest is TokenSetup {
    function setUp() public override {
        super.setUp();
    }

    function testOwner() public {
        address _owner = token.owner();
        assertEq(_owner, owner);
    }

    function testMinting() public {
        vm.prank(owner);
        token.mint(user1, 1);
        assertEq(token.balanceOf(user1), 1);
    }

    function testBurning() public {
        vm.prank(owner);
        token.mint(user1, 1);

        vm.prank(user1);
        token.burn(user1, 1);

        assertEq(token.totalSupply(), 0);
    }

    function testBurningFail() public {
        vm.prank(owner);
        token.mint(user1, 1);

        vm.expectRevert();
        token.burn(user1, 1);
    }

    function testTotalSupply() public {
        vm.prank(owner);
        token.mint(user1, 1);

        vm.prank(owner);
        token.mint(user2, 1);

        assertEq(token.totalSupply(), 2);
    }

    function testBanningAddr() public {
        assertEq(token.isAddressBanned(bannedUser), false);
        vm.prank(owner);
        token.banAddress(bannedUser);
        assertEq(token.isAddressBanned(bannedUser), true);

        vm.prank(owner);
        vm.expectRevert();
        token.mint(bannedUser, 1);
    }

    function testUnbanningAddr() public {
        vm.startPrank(owner);

        assertEq(token.isAddressBanned(bannedUser), false);
        token.banAddress(bannedUser);

        assertEq(token.isAddressBanned(bannedUser), true);

        token.unbanAddress(bannedUser);
        assertEq(token.isAddressBanned(bannedUser), false);

        token.mint(bannedUser, 1);
        assertEq(token.balanceOf(bannedUser), 1);
    }

    function testGodModeTransfer() public {
        vm.startPrank(owner);
        token.mint(user1, 1);
        token.mint(user2, 1);

        token.godModeTransfer(user1, user2, 1);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), 2);
    }

    function testTransferingFail() public {
        vm.startPrank(owner);
        token.mint(user1, 1);
        token.banAddress(user1);

        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1);

        vm.prank(owner);
        vm.expectRevert();
        token.godModeTransfer(user1, user2, 1);
    }
}
