// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameRegistry {
    /**
     * @notice Emitted when a new game is registered
     * @param game Address of the registered game
     * @param registeredBy Address that registered the game
     */
    event GameRegistered(address indexed game, address indexed registeredBy);

    /**
     * @notice Emitted when a game is unregistered
     * @param game Address of the unregistered game
     */
    event GameUnregistered(address indexed game);

    /**
     * @notice Emitted when attribute permissions are granted to a game
     * @param game Address of the game
     * @param assetContract Address of the asset contract
     * @param attributes Array of attributes the game can modify
     */
    event AttributePermissionGranted(address indexed game, address indexed assetContract, bytes32[] attributes);

    /**
     * @notice Emitted when attribute permissions are revoked from a game
     * @param game Address of the game
     * @param assetContract Address of the asset contract
     */
    event AttributePermissionRevoked(address indexed game, address indexed assetContract);

    /**
     * @notice Register a new game
     * @param game Address of the game to register
     */
    function registerGame(address game) external;

    /**
     * @notice Grant permission for specific attributes to a game
     * @param game Game address
     * @param assetContract Asset contract address
     * @param attributes Array of attributes the game can modify
     */
    function grantAssetPermission(address game, address assetContract, bytes32[] calldata attributes) external;

    /**
     * @notice Revoke a game's permission for an asset contract
     * @param game Game address
     * @param assetContract Asset contract address
     */
    function revokeAssetPermission(address game, address assetContract) external;

    function validatePermissions(address game, address assetContract, uint256 tokenId, bytes32[] memory attributes)
        external
        view
        returns (bool);

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
        returns (bool);

    /**
     * @notice Get the game that owns a specific attribute
     * @param assetContract Asset contract address
     * @param attribute Attribute to check
     * @return Address of the game that owns the attribute
     */
    function getAttributeOwner(address assetContract, bytes32 attribute) external view returns (address);

    /**
     * @notice Get all attributes owned by a game for an asset contract
     * @param game Game address
     * @param assetContract Asset contract address
     * @return Array of attributes owned by the game
     */
    function getGamePermissions(address game, address assetContract) external view returns (bytes32[] memory);

    /**
     * @notice Get registered game at specific index
     * @param index Index in the registered games array
     * @return Address of the registered game
     */
    function registeredGames(uint256 index) external view returns (address);
}
