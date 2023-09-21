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

        user2 = vm.addr(999);

        bannedUser = vm.addr(777);

        vm.prank(owner);
        sale = new BondingCurveSale("Token", "TKN");
    }

    function testSetUp() public {
        assertEq(sale.totalSupply(), 0);
        assertEq(sale.name(), "Token");
        assertEq(sale.symbol(), "TKN");
        assertEq(sale.pricePerToken(), 1 ether);
    }

    function testBuyFail() public {
        uint256 tokenAmount = 5 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 5 tokens is %s", buyPrice);

        vm.deal(user1, 100 ether);
        vm.prank(user1);
        vm.expectRevert();
        sale.buy{value: buyPrice}(tokenAmount + 1);
    }

    function testBuyAndSell() public {
        uint256 tokenAmount = 5 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 5 tokens is %s", buyPrice);

        vm.prank(user1);
        vm.deal(user1, 100 ether);
        sale.buy{value: buyPrice}(tokenAmount);

        console2.log("user1 bought 5 tokens");
        console2.log("Current eth balance of contract: %s", address(sale).balance);

        buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 5 more tokens (from 5 to 10) is %s", buyPrice);

        vm.prank(user1);
        vm.deal(user1, 100 ether);
        sale.buy{value: buyPrice}(tokenAmount);
        console2.log("user1 buys 5 more tokens");
        console2.log("Current eth balance of contract: %s", address(sale).balance);
        console2.log("Current 'totalSupply' : %s", sale.totalSupply() / 10 ** 18);

        vm.prank(user1);
        sale.transferAndCall(address(sale), 5 ether, bytes(""));
        console2.log("user1 sends 5 tokens to 'sale' (automatic sell)");
        console2.log("Current eth balance of contract: %s", address(sale).balance);
        console2.log("Current 'totalSupply': %s", sale.totalSupply() / 10 ** 18);
    }

    function testBuyWithDecimals() public {
        uint256 tokenAmount = 5 ether;
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 5 tokens is %s", buyPrice);
        vm.prank(user1);
        vm.deal(user1, 100 ether);
        sale.buy{value: buyPrice}(tokenAmount);

        tokenAmount = 4.9 ether;
        buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 4.9 tokens is %s", buyPrice);
        vm.prank(user2);
        vm.deal(user2, 100 ether);
        sale.buy{value: buyPrice}(tokenAmount);

        tokenAmount = 0.1 ether;
        buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 0.1 tokens is %s", buyPrice);
        vm.prank(user2);
        vm.deal(user2, 100 ether);
        sale.buy{value: buyPrice}(tokenAmount);

        console2.log("Current eth balance of contract: %s", address(sale).balance / 10 ** 18);
        console2.log("Current 'totalSupply': %s", sale.totalSupply() / 10 ** 18);
        console2.log("'currentPrice': %s", sale.currentPrice() / 10 ** 18);
    }

    function testTotalMarketValue() public {
        uint256 tokenAmount = 1_000_000 ether; // a million tokens
        uint256 buyPrice = sale.buyPriceCalculation(tokenAmount);
        console2.log("'buyPrice' for 1_000_000 tokens is %s", buyPrice / 10 ** 18);
        assertEq(buyPrice / 10 ** 18, 500_001_000_000);
    }
}
