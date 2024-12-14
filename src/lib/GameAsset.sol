// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IGameRegistry.sol";
import "./IGameAsset.sol";

contract GameAsset is ERC721, ReentrancyGuard, IGameAsset {
    // Game registry contract reference
    IGameRegistry public immutable gameRegistry;

    // Mapping: tokenId => attribute => value
    mapping(uint256 => mapping(bytes32 => bytes)) private attributes;

    event AttributesUpdated(uint256 indexed tokenId, address indexed game, bytes32[] attributeTypes, bytes[] values);

    constructor(string memory name, string memory symbol, address gameRegistryAddress) ERC721(name, symbol) {
        require(gameRegistryAddress != address(0), "Invalid registry address");
        gameRegistry = IGameRegistry(gameRegistryAddress);
    }

    /**
     * @notice Get attributes for a token
     * @param tokenId Token ID to query
     * @param attributeTypes Array of attribute types to get
     * @return Array of attribute values
     */
    function getAttributes(uint256 tokenId, bytes32[] calldata attributeTypes)
        external
        view
        override
        returns (bytes[] memory)
    {
        // This will revert if token doesn't exist
        ownerOf(tokenId);

        bytes[] memory values = new bytes[](attributeTypes.length);
        for (uint256 i = 0; i < attributeTypes.length; i++) {
            values[i] = attributes[tokenId][attributeTypes[i]];
        }
        return values;
    }

    /**
     * @notice Update attributes for a token
     * @param tokenId Token ID to update
     * @param attributeTypes Array of attribute types to update
     * @param values Array of corresponding values
     */
    function updateAttributes(uint256 tokenId, bytes32[] calldata attributeTypes, bytes[] calldata values)
        external
        override
        nonReentrant
    {
        // This will revert if token doesn't exist
        ownerOf(tokenId);

        require(attributeTypes.length == values.length, "Length mismatch");

        // Check if caller has permission through game registry
        require(gameRegistry.hasPermissions(msg.sender, address(this), attributeTypes), "Caller lacks permission");

        // Update attributes
        for (uint256 i = 0; i < attributeTypes.length; i++) {
            attributes[tokenId][attributeTypes[i]] = values[i];
        }

        emit AttributesUpdated(tokenId, msg.sender, attributeTypes, values);
    }

    /**
     * @notice Get specific attribute for a token
     * @param tokenId Token ID to query
     * @param attributeType Attribute type to get
     * @return Attribute value
     */
    function getAttribute(uint256 tokenId, bytes32 attributeType) external view returns (bytes memory) {
        // This will revert if token doesn't exist
        ownerOf(tokenId);
        return attributes[tokenId][attributeType];
    }

    /**
     * @notice Mint new token with attributes
     * @param to Address to mint to
     * @param tokenId Token ID to mint
     * @param attributeTypes Initial attribute types
     * @param values Initial attribute values
     */
    function mint(address to, uint256 tokenId, bytes32[] calldata attributeTypes, bytes[] calldata values) external {
        require(attributeTypes.length == values.length, "Length mismatch");
        require(gameRegistry.hasPermissions(msg.sender, address(this), attributeTypes), "Caller lacks permission");

        _mint(to, tokenId);

        // Set initial attributes
        for (uint256 i = 0; i < attributeTypes.length; i++) {
            attributes[tokenId][attributeTypes[i]] = values[i];
        }

        emit AttributesUpdated(tokenId, msg.sender, attributeTypes, values);
    }
}
