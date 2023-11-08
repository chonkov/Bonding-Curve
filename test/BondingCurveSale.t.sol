// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {BondingCurveSale} from "../src/BondingCurveSale.sol";

contract BondingCurveSaleTest is Test {
    BondingCurveSale internal sale;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal bannedUser;

    function setUp() public virtual {
        owner = vm.addr(444);

        user1 = vm.addr(666);
        vm.deal(user1, 1000 ether);

        user2 = vm.addr(999);
        vm.deal(user2, 1000 ether);

        bannedUser = vm.addr(777);

        vm.prank(owner);
        sale = new BondingCurveSale("Token", "TKN");
    }

    function testSetUp() public {
        assertEq(sale.totalSupply(), 0);
        assertEq(sale.name(), "Token");
        assertEq(sale.symbol(), "TKN");
        assertEq(sale.pricePerToken(), 1 ether);
        assertEq(sale.currentPrice(), sale.basePrice());
    }

    function testBuyPrice() public {
        uint256 tokenAmount = 4 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);
        assertEq(buyPrice, 12 ether);

        buyPrice = sale.buyPriceCalculation(tokenAmount * 5 / 2);
        assertEq(buyPrice, 60 ether);

        buyPrice = sale.buyPriceCalculation(tokenAmount - 2 ether);
        assertEq(buyPrice, 4 ether);

        buyPrice = sale.buyPriceCalculation(tokenAmount - 3 ether);
        assertEq(buyPrice, 3 ether / 2);
    }

    function testBuy() public {
        uint256 tokenAmount = 5 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.startPrank(user1);
        sale.buy{value: buyPrice}(tokenAmount);
        assertEq(address(sale).balance, buyPrice);
        assertEq(sale.currentPrice(), 6 ether);

        buyPrice = sale.buyPriceCalculation(tokenAmount);
        assertEq(buyPrice, 85 ether / 2);
        uint256 balance = address(sale).balance;

        sale.buy{value: buyPrice}(tokenAmount);
        assertEq(address(sale).balance, balance + buyPrice);
        assertEq(sale.totalSupply(), tokenAmount * 2);
        assertEq(sale.balanceOf(user1), tokenAmount * 2);
        vm.stopPrank();
    }

    function testBuyWithDecimals() public {
        uint256 tokenAmount = 5 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.prank(user1);
        sale.buy{value: buyPrice}(tokenAmount);

        tokenAmount = 4.9 ether;
        buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.prank(user2);
        sale.buy{value: buyPrice}(tokenAmount);

        tokenAmount = 0.1 ether;
        buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.prank(user2);
        sale.buy{value: buyPrice}(tokenAmount);

        assertEq(address(sale).balance, 60 ether);
        assertEq(sale.totalSupply(), 10 ether);
        assertEq(sale.balanceOf(user1), sale.balanceOf(user2));
    }

    function testBuyFail() public {
        uint256 tokenAmount = 10 ether;
        uint256 ethRequired = sale.buyPriceCalculation(tokenAmount); // 10 tokens -> 60 ether as a depostit

        vm.prank(user1);
        vm.expectRevert("Actual amount of tokens is less than expected minimum");
        sale.buy{value: ethRequired - 1}(tokenAmount);
    }

    function testSell() public {
        uint256 tokenAmount = 10 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.startPrank(user1);
        sale.buy{value: buyPrice}(tokenAmount);

        uint256 balance = address(sale).balance;
        uint256 salePrice = sale.sellPriceCalculation(tokenAmount / 2);

        sale.transferAndCall(address(sale), tokenAmount / 2, abi.encode(salePrice));
        assertEq(address(sale).balance, balance - salePrice);
        assertEq(sale.totalSupply(), tokenAmount / 2);
        assertEq(sale.balanceOf(user1), tokenAmount / 2);
        vm.stopPrank();
    }

    function testSellFail() public {
        uint256 tokenAmount = 10 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.startPrank(user1);
        sale.buy{value: buyPrice}(tokenAmount);

        uint256 salePrice = sale.sellPriceCalculation(tokenAmount / 2);

        vm.expectRevert("Actual amount of ether is less than expected minimum");
        sale.transferAndCall(address(sale), tokenAmount / 2, abi.encode(salePrice + 1));
        vm.stopPrank();
    }

    function testBuyAndSellFailedTransfers() public {
        vm.deal(address(this), 100 ether);
        assertEq(address(this).balance, 100 ether);

        uint256 tokenAmount = 10 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);

        vm.expectRevert("Unsuccessful call");
        sale.buy{value: buyPrice + 1}(tokenAmount);

        sale.buy{value: buyPrice}(tokenAmount);

        vm.expectRevert("Unsuccessful call");
        sale.transferAndCall(address(sale), 1, abi.encode(1));
    }

    receive() external payable {
        if (msg.value > 0) revert();
    }
}
