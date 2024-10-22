// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GameItem is ERC721URIStorage, Ownable {
    // Mapping of tokenId to dynamic set of attributes (key-value pairs)
    mapping(uint256 => mapping(string => uint256)) private _attributes;
    mapping(uint256 => mapping(string => bool)) private _attributeLocked;

    // Event to emit when an attribute is updated
    event AttributeUpdated(uint256 indexed tokenId, string attributeName, uint256 newValue);

    // Event to emit when an attribute is locked
    event AttributeLocked(uint256 indexed tokenId, string attributeName);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Function to set or update an attribute (if not locked)
    function _setAttribute(uint256 tokenId, string memory attributeName, uint256 value) internal virtual {
        require(!_attributeLocked[tokenId][attributeName], "Attribute is locked");
        _attributes[tokenId][attributeName] = value;
        emit AttributeUpdated(tokenId, attributeName, value);
    }

    // Function to lock an attribute so it cannot be modified
    function _lockAttribute(uint256 tokenId, string memory attributeName) internal virtual {
        _attributeLocked[tokenId][attributeName] = true;
        emit AttributeLocked(tokenId, attributeName);
    }

    // Function to retrieve an attribute's value
    function getAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256) {
        return _attributes[tokenId][attributeName];
    }

    // Function to check if an attribute is locked
    function isAttributeLocked(uint256 tokenId, string memory attributeName) public view returns (bool) {
        return _attributeLocked[tokenId][attributeName];
    }

    // Abstract function to specify initial attributes, to be implemented in child contracts
    function initializeAttributes(uint256 tokenId) internal virtual;

    // Mint function that mints a new item and initializes attributes
    function mintItem(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        require(_ownerOf(tokenId) == address(0), "Token already exists");
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        initializeAttributes(tokenId);
    }
}
