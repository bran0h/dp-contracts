// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/GameImplementation.sol";
import "./lib/IGameRegistry.sol";
import "./lib/IGameAsset.sol";

contract RPGame is GameImplementation {
    // Constants for attribute names
    bytes32 public constant HASTE_ATTR = keccak256("rpgame.item.haste");
    bytes32 public constant DAMAGE_ATTR = keccak256("rpgame.item.damage");

    IGameRegistry public immutable gameRegistry;

    // Constants for attribute limits
    uint256 public constant MAX_HASTE = 1000;
    uint256 public constant MAX_DAMAGE = 10000;

    // Events
    event SwordAttributesUpdated(uint256 indexed tokenId, uint256 haste, uint256 damage);

    constructor(address gameRegistryAddress, uint256 requiredApprovals, uint256 proposalTimeout, uint256 updateTimelock)
        GameImplementation(requiredApprovals, proposalTimeout, updateTimelock)
    {
        gameRegistry = IGameRegistry(gameRegistryAddress);
    }

    function _validateAttributeValue(bytes32 attributeType, bytes memory value) internal pure override returns (bool) {
        uint256 decodedValue = abi.decode(value, (uint256));

        if (attributeType == HASTE_ATTR) {
            return decodedValue <= MAX_HASTE;
        } else if (attributeType == DAMAGE_ATTR) {
            return decodedValue <= MAX_DAMAGE;
        }

        return false;
    }

    function _updateAttributesInternal(uint256 tokenId, bytes memory encodedAttributes) internal override {
        (bytes32[] memory attributes, bytes[] memory values) = _decodeAttributes(encodedAttributes);

        // Update using the game asset interface
        IGameAsset(assetContracts[attributes[0]]).updateAttributes(tokenId, attributes, values);
    }

    function _encodeAttributes(bytes32[] memory attributes, bytes[] memory values)
        internal
        pure
        override
        returns (bytes memory)
    {
        return abi.encode(attributes, values);
    }

    function _decodeAttributes(bytes memory data)
        internal
        pure
        override
        returns (bytes32[] memory attributes, bytes[] memory values)
    {
        return abi.decode(data, (bytes32[], bytes[]));
    }

    /**
     * @notice Update sword attributes
     * @param assetContract Asset contract address
     * @param tokenId Token ID of the sword
     * @param haste New haste value
     * @param damage New damage value
     */
    function updateSwordAttributes(address assetContract, uint256 tokenId, uint256 haste, uint256 damage) external {
        require(haste <= MAX_HASTE, "Haste exceeds maximum");
        require(damage <= MAX_DAMAGE, "Damage exceeds maximum");

        // Prepare attributes and values
        bytes32[] memory attrTypes = new bytes32[](2);
        attrTypes[0] = HASTE_ATTR;
        attrTypes[1] = DAMAGE_ATTR;

        bytes[] memory values = new bytes[](2);
        values[0] = abi.encode(haste);
        values[1] = abi.encode(damage);

        // Validate permissions through registry
        require(
            gameRegistry.validatePermissions(address(this), assetContract, tokenId, attrTypes),
            "RPGame: Invalid permissions"
        );

        // Update attributes
        IGameAsset(assetContract).updateAttributes(tokenId, attrTypes, values);

        emit SwordAttributesUpdated(tokenId, haste, damage);
    }

    /**
     * @notice Get sword attributes
     * @param assetContract Asset contract address
     * @param tokenId Token ID of the sword
     * @return haste Current haste value
     * @return damage Current damage value
     */
    function getSwordAttributes(address assetContract, uint256 tokenId)
        external
        view
        returns (uint256 haste, uint256 damage)
    {
        bytes32[] memory attrTypes = new bytes32[](2);
        attrTypes[0] = HASTE_ATTR;
        attrTypes[1] = DAMAGE_ATTR;

        bytes[] memory values = IGameAsset(assetContract).getAttributes(tokenId, attrTypes);

        haste = abi.decode(values[0], (uint256));
        damage = abi.decode(values[1], (uint256));
    }
}
