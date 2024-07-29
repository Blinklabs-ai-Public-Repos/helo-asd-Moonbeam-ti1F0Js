// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CustomToken
 * @dev ERC20 token with multisend, gasless transactions, and pausable features
 * @notice This contract implements an ERC20 token with additional functionality
 */
contract CustomToken is ERC20, ERC20Permit, ERC20Pausable, Multicall, Ownable {
    uint256 private immutable _maxSupply;

    /**
     * @dev Constructor to initialize the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param maxSupply_ The maximum supply of the token
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        require(maxSupply_ > 0, "CustomToken: Max supply must be greater than 0");
        _maxSupply = maxSupply_;
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the maximum supply of the token
     * @return The maximum supply
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Mints new tokens
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     * @notice Only the contract owner can mint new tokens
     */
    function mint(address to, uint256 amount) public virtual onlyOwner {
        require(totalSupply() + amount <= _maxSupply, "CustomToken: Exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @dev Overrides the _beforeTokenTransfer function to include pausable functionality
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param amount The amount of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Pauses all token transfers
     * @notice Only the contract owner can pause transfers
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     * @notice Only the contract owner can unpause transfers
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Multisend function to send tokens to multiple addresses
     * @param recipients An array of recipient addresses
     * @param amounts An array of amounts to send to each recipient
     * @notice This function allows sending tokens to multiple addresses in a single transaction
     */
    function multisend(address[] memory recipients, uint256[] memory amounts) public virtual {
        require(recipients.length == amounts.length, "CustomToken: Arrays length mismatch");
        require(recipients.length > 0, "CustomToken: Empty recipients array");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(balanceOf(_msgSender()) >= totalAmount, "CustomToken: Insufficient balance for multisend");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "CustomToken: Cannot send to zero address");
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }
}