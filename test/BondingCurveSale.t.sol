// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BondingCurveSale} from "../src/BondingCurveSale.sol";

contract BondingCurveSaleTest is Test {
    BondingCurveSale public sale;

    function setUp() public {
        sale = new BondingCurveSale("Token", "TKN");
    }

    function testSetUp() public {
        assertEq(sale.totalSupply(), 0);
        assertEq(sale.name(), "Token");
        assertEq(sale.symbol(), "TKN");
    }
}
