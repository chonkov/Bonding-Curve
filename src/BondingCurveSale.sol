// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Token} from "./Token.sol";
import "erc-1363/ERC1363/IERC1363Receiver.sol";

/// @title BondginCurveSale
/// @author Georgi
/// @notice Bonding curve token sale that uses the 'Token' contract
contract BondingCurveSale is Token, IERC1363Receiver {
    uint256 public constant basicPrice = 0.001 ether;
    uint256 public constant pricePerToken = 0.1 gwei;

    constructor(string memory _name, string memory _symbol) Token(_name, _symbol) {}

    /// @notice Buy tokens with ethers
    /// @param amount uinst256 Amount of token to buy
    function buy(uint256 amount) external payable {
        require(msg.value == buyPriceCalculation(amount), "msg.value deos not match price of tokens");
        _mint(msg.sender, amount);
    }

    /// @notice Automatic sell when tranfering to contract
    /// @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
    /// @param from address The address which are token transferred from
    /// @param amount uint256 The amount of tokens transferred
    /// @param data bytes Additional data with no specified format
    function onTransferReceived(address operator, address from, uint256 amount, bytes memory data)
        external
        returns (bytes4)
    {
        (uint256 curveBasePrice, uint256 curveExtraPrice) = _calculatePrice(amount);
        _burn(address(this), amount);
        payable(from).transfer(curveBasePrice - curveExtraPrice);
        return type(IERC1363Receiver).interfaceId;
    }

    /// @notice Calculation of ether price for amount of tokens
    /// @param amount uint256 The amount of tokens to calculate price for
    /// @return Price to pay for the given amount
    function buyPriceCalculation(uint256 amount) public view returns (uint256) {
        (uint256 curveBasePrice, uint256 curveExtraPrice) = _calculatePrice(amount);
        return (curveBasePrice + curveExtraPrice);
    }

    /// @notice Get the corrent price for a token
    /// @return Current Price for a single token
    function currentPrice() external view returns (uint256) {
        return pricePerToken * totalSupply();
    }

    function _calculatePrice(uint256 amount) internal view returns (uint256 curveBasePrice, uint256 curveExtraPrice) {
        uint256 _currentPrice = basicPrice + (pricePerToken * totalSupply()) / 10 ** decimals();
        curveBasePrice = ((amount * _currentPrice)) / 10 ** decimals();
        curveExtraPrice = (((amount * pricePerToken) / 10 ** decimals()) * (amount)) / (2 * 10 ** decimals());
    }
}
