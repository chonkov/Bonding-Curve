// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {ERC1363, ERC20} from "lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";

import {IERC1363Receiver} from "lib/erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";

// NOTE:

// Problem with Cooldown:
// If an attacker has 2 wallets(addresses), they can execute 'buy' with one of them(front-run the victim), send those newely bought tokens
// to their second account and then sell, therefore going around and passing the cooldown mechanism and perform the sandwich attack

/// @title BondingCurveSale
/// @author Georgi
/// @notice Bonding curve token sale that uses the ERC1363
contract BondingCurveSale is ERC1363, IERC1363Receiver {
    event Buy(address indexed, uint256);
    event Sell(address indexed, uint256);

    uint256 public constant basePrice = 1 ether;
    uint256 public constant pricePerToken = 1 ether;
    // mapping(address => uint256) public cooldown;
    // uint256 public constant cooldownPeriod = 5; // blocks

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    // Not a great option - slippage is better
    // modifier coolDown(address account) {
    //     require(block.number >= cooldown[account], "Cooldown period has not expired yet");
    //     cooldown[account] = block.number + cooldownPeriod;
    //     _;
    // }

    /// @notice Buy tokens with ethers
    /// @param amount uinst256 Amount of token to buy
    function buy(uint256 amount) external payable {
        uint256 ethRequired = buyPriceCalculation(amount);
        require(msg.value >= ethRequired, "Actual amount of tokens is less than expected minimum");

        _mint(msg.sender, amount);

        (bool success,) = msg.sender.call{value: msg.value - ethRequired}(""); // Excess is returned
        require(success, "Unsuccessful call");

        emit Buy(msg.sender, amount);
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
        uint256 ethToReturn = sellPriceCalculation(amount);
        uint256 minExpectedAmount = abi.decode(data, (uint256));
        require(ethToReturn >= minExpectedAmount, "Actual amount of ether is less than expected minimum");

        _burn(address(this), amount);

        (bool success,) = from.call{value: ethToReturn}("");
        require(success, "Unsuccessful call");

        emit Sell(operator, amount);
        return type(IERC1363Receiver).interfaceId;
    }

    /// @notice Calculation of ether price for amount of tokens
    /// @param amount uint256 The amount of tokens to calculate price for
    /// @return Price to pay for the given amount
    function buyPriceCalculation(uint256 amount) public view returns (uint256) {
        (uint256 curveBasePrice, uint256 curveExtraPrice) = _calculatePrice(amount);
        return (curveBasePrice + curveExtraPrice);
    }

    /// @notice Calculation of amount of tokens for ether
    /// @param amount uint256 The amount of tokens to calculate price for
    /// @return Amount to send back for the received tokens
    function sellPriceCalculation(uint256 amount) public view returns (uint256) {
        (uint256 curveBasePrice, uint256 curveExtraPrice) = _calculatePrice(amount);
        return (curveBasePrice - curveExtraPrice);
    }

    /// @notice Get the correct price for a token
    /// @return Current Price for a SINGLE token in WEI
    function currentPrice() public view returns (uint256) {
        return basePrice + (pricePerToken * totalSupply() / 10 ** decimals());
    }

    function _calculatePrice(uint256 amount) internal view returns (uint256 curveBasePrice, uint256 curveExtraPrice) {
        uint256 _currentPrice = currentPrice();
        curveBasePrice = ((amount * _currentPrice)) / 10 ** decimals();
        curveExtraPrice = (((amount * pricePerToken) / 10 ** decimals()) * (amount)) / (2 * 10 ** decimals());
    }
}
