// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Token
/// @author Georgi
/// @notice This contract is an ERC1363 contract with sanctions and god mode functionnalities
contract Token is ERC1363, Ownable {
    event Ban(address indexed);
    event Unban(address indexed);

    mapping(address => bool) private bannedAddress;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @notice Owner is able to mint tokens
    /// @param to Address to which token will be minter
    /// @param amount Amount of token to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);

        emit Transfer(address(0), to, amount);
    }

    /// @notice Burn tokens
    /// @param from Address from which token will be burned
    /// @param amount Amount of token to burn

    function burn(address from, uint256 amount) external {
        require(from == msg.sender, "from address must be sender");
        _burn(from, amount);

        emit Transfer(from, address(0), amount);
    }

    /// @notice Owner is able to ban address
    /// @param _bannedAddress Address to ban
    function banAddress(address _bannedAddress) external onlyOwner {
        bannedAddress[_bannedAddress] = true;

        emit Ban(_bannedAddress);
    }

    /// @notice Owner is able to unban address
    /// @param _unbannedAddress Address to unban
    function unbanAddress(address _unbannedAddress) external onlyOwner {
        bannedAddress[_unbannedAddress] = false;

        emit Unban(_unbannedAddress);
    }

    /// @notice Allows user to know if an address has been banned
    /// @param _address Address to test is banned ou unbanned
    function isAddressBanned(address _address) external view returns (bool) {
        return bannedAddress[_address];
    }

    /// @notice Owner has god mode and is able to transfer tokens from every address
    /// @param from Address from which token will be transfered
    /// @param to Address to which token will be transfered
    /// @param amount Amount of token to transfer
    function godModeTransfer(address from, address to, uint256 amount) external onlyOwner {
        _transfer(from, to, amount);

        emit Transfer(from, to, amount);
    }

    /// @notice Use of _beforeTokenTransfer hook for ban mechanism
    /// @param from Address from which token will be transfered
    /// @param to Address to which token will be transfered
    /// @param amount Amount of token to transfer
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        require(bannedAddress[from] == false, "Banned address");
        require(bannedAddress[to] == false, "Banned address");
    }
}
