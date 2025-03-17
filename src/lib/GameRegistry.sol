// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGameRegistry.sol";
import "./IGameAsset.sol";

contract GameRegistry is Ownable, IGameRegistry {
    struct AttributePermission {
        bool isRegistered;
        bytes32[] allowedAttributes;
    }

    struct GameData {
        bool isRegistered;
        // Mapping: asset contract address => permissions
        mapping(address => AttributePermission) assetPermissions;
        uint256 registrationTime;
        address registeredBy;
    }

    // Mapping: game address => game data
    mapping(address => GameData) private games;

    // Mapping: asset contract => attribute => owning game
    // This ensures each attribute can only be modified by one game
    mapping(address => mapping(bytes32 => address)) public attributeOwnership;

    // Store all registered games for iteration
    address[] public registeredGames;

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Check if a token exists in the asset contract
     * @param assetContract Asset contract address
     * @param tokenId Token ID to check
     */
    modifier tokenExists(address assetContract, uint256 tokenId) {
        // ownerOf will revert if token doesn't exist
        IGameAsset(assetContract).ownerOf(tokenId);
        _;
    }

    /**
     * @notice Register a new game
     * @param game Address of the game to register
     */
    function registerGame(address game) external onlyOwner {
        require(game != address(0), "Invalid game address");
        require(!games[game].isRegistered, "Game already registered");

        games[game].isRegistered = true;
        games[game].registrationTime = block.timestamp;
        games[game].registeredBy = msg.sender;

        registeredGames.push(game);
        emit GameRegistered(game, msg.sender);
    }

    /**
     * @notice Grant permission for specific attributes to a game
     * @param game Game address
     * @param assetContract Asset contract address
     * @param attributes Array of attributes the game can modify
     */
    function grantAssetPermission(address game, address assetContract, bytes32[] calldata attributes)
        external
        onlyOwner
    {
        require(games[game].isRegistered, "Game not registered");
        require(assetContract != address(0), "Invalid asset contract");
        require(attributes.length > 0, "No attributes specified");

        // Check if any attributes are already owned by another game
        for (uint256 i = 0; i < attributes.length; i++) {
            address currentOwner = attributeOwnership[assetContract][attributes[i]];
            require(currentOwner == address(0) || currentOwner == game, "Attribute already owned by another game");
        }

        // Grant permissions
        AttributePermission storage permission = games[game].assetPermissions[assetContract];
        permission.isRegistered = true;
        permission.allowedAttributes = attributes;

        // Register attribute ownership
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeOwnership[assetContract][attributes[i]] = game;
        }

        emit AttributePermissionGranted(game, assetContract, attributes);
    }

    /**
     * @notice Check if a game has permission for specific attributes and token exists
     * @param game Game address
     * @param assetContract Asset contract address
     * @param tokenId Token ID to check
     * @param attributes Array of attributes to check
     * @return bool indicating if the game has all permissions and token exists
     */
    function validatePermissions(address game, address assetContract, uint256 tokenId, bytes32[] memory attributes)
        external
        view
        returns (bool)
    {
        if (!games[game].isRegistered) {
            return false;
        }

        // Check if token exists by trying to get its owner
        try IGameAsset(assetContract).ownerOf(tokenId) returns (address) {
            // Token exists, now check permissions
            for (uint256 i = 0; i < attributes.length; i++) {
                if (attributeOwnership[assetContract][attributes[i]] != game) {
                    return false;
                }
            }
            return true;
        } catch {
            // Token doesn't exist
            return false;
        }
    }

    /**
     * @notice Revoke a game's permission for an asset contract
     * @param game Game address
     * @param assetContract Asset contract address
     */
    function revokeAssetPermission(address game, address assetContract) external onlyOwner {
        require(games[game].isRegistered, "Game not registered");
        require(games[game].assetPermissions[assetContract].isRegistered, "Asset not registered for game");

        // Remove attribute ownership
        bytes32[] storage attributes = games[game].assetPermissions[assetContract].allowedAttributes;
        for (uint256 i = 0; i < attributes.length; i++) {
            delete attributeOwnership[assetContract][attributes[i]];
        }

        delete games[game].assetPermissions[assetContract];
        emit AttributePermissionRevoked(game, assetContract);
    }

    /**
     * @notice Check if a game has permission to modify specific attributes
     * @param game Game address
     * @param assetContract Asset contract address
     * @param attributes Array of attributes to check
     * @return bool indicating if the game has permission for ALL specified attributes
     */
    function hasPermissions(address game, address assetContract, bytes32[] calldata attributes)
        external
        view
        returns (bool)
    {
        if (!games[game].isRegistered) {
            return false;
        }

        // Check ownership of each attribute
        for (uint256 i = 0; i < attributes.length; i++) {
            if (attributeOwnership[assetContract][attributes[i]] != game) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Get the game that owns a specific attribute
     * @param assetContract Asset contract address
     * @param attribute Attribute to check
     * @return Address of the game that owns the attribute
     */
    function getAttributeOwner(address assetContract, bytes32 attribute) external view returns (address) {
        return attributeOwnership[assetContract][attribute];
    }

    /**
     * @notice Get all attributes owned by a game for an asset contract
     * @param game Game address
     * @param assetContract Asset contract address
     * @return Array of attributes owned by the game
     */
    function getGamePermissions(address game, address assetContract) external view returns (bytes32[] memory) {
        require(games[game].isRegistered, "Game not registered");
        require(games[game].assetPermissions[assetContract].isRegistered, "Asset not registered for game");

        return games[game].assetPermissions[assetContract].allowedAttributes;
    }

    /**
     * @notice Get token attributes if game has permission to read them
     * @param game Game requesting the attributes
     * @param assetContract Asset contract address
     * @param tokenId Token ID to query
     * @param attributes Array of attributes to get
     * @return Array of attribute values
     */
    function getTokenAttributes(address game, address assetContract, uint256 tokenId, bytes32[] calldata attributes)
        external
        view
        tokenExists(assetContract, tokenId)
        returns (bytes[] memory)
    {
        require(games[game].isRegistered, "Game not registered");

        // Check permissions
        for (uint256 i = 0; i < attributes.length; i++) {
            require(attributeOwnership[assetContract][attributes[i]] == game, "Game lacks permission");
        }

        return IGameAsset(assetContract).getAttributes(tokenId, attributes);
    }
}
