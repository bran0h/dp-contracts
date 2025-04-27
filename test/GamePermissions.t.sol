// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/lib/GameRegistry.sol";
import "../src/lib/GameAsset.sol";
import "../src/lib/IGameAsset.sol";

contract GamePermissionsTest is Test {
    GameRegistry public registry;
    address public owner;
    address public user;
    address public game1;
    address public game2;
    address public assetContract;

    bytes32 public constant HEALTH_ATTR = keccak256("HEALTH");
    bytes32 public constant DAMAGE_ATTR = keccak256("DAMAGE");
    bytes32 public constant ARMOR_ATTR = keccak256("ARMOR");

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        game1 = address(0x2);
        game2 = address(0x3);
        assetContract = address(0x4);

        // Deploy registry
        registry = new GameRegistry();

        // Register games
        registry.registerGame(game1);
        registry.registerGame(game2);
    }

    function test_RevertWhen_GrantPermissionToUnregisteredGame() public {
        address unregisteredGame = address(0x5);

        bytes32[] memory attributes = new bytes32[](1);
        attributes[0] = HEALTH_ATTR;

        // Should fail because game is not registered
        vm.expectRevert();
        registry.grantAssetPermission(unregisteredGame, assetContract, attributes);
    }

    function test_RevertWhen_GrantOverlappingPermissions() public {
        // First grant HEALTH attribute to game1
        bytes32[] memory attributes1 = new bytes32[](1);
        attributes1[0] = HEALTH_ATTR;
        registry.grantAssetPermission(game1, assetContract, attributes1);

        // Then try to grant the same attribute to game2
        // This should fail because HEALTH is already owned by game1
        bytes32[] memory attributes2 = new bytes32[](1);
        attributes2[0] = HEALTH_ATTR;
        vm.expectRevert();
        registry.grantAssetPermission(game2, assetContract, attributes2);
    }

    function test_RevertWhen_GrantEmptyAttributes() public {
        // Trying to grant empty attributes array should fail
        bytes32[] memory emptyAttributes = new bytes32[](0);
        vm.expectRevert();
        registry.grantAssetPermission(game1, assetContract, emptyAttributes);
    }

    function test_RevertWhen_GrantPermissionForInvalidAssetContract() public {
        bytes32[] memory attributes = new bytes32[](1);
        attributes[0] = HEALTH_ATTR;

        // Try with zero address for asset contract
        vm.expectRevert();
        registry.grantAssetPermission(game1, address(0), attributes);
    }

    function testRevokePermissionAndRegrant() public {
        // Grant permissions
        bytes32[] memory attributes = new bytes32[](2);
        attributes[0] = HEALTH_ATTR;
        attributes[1] = DAMAGE_ATTR;
        registry.grantAssetPermission(game1, assetContract, attributes);

        // Check permissions
        assertTrue(registry.hasPermissions(game1, assetContract, attributes));

        // Revoke permissions
        registry.revokeAssetPermission(game1, assetContract);

        // Check permissions are revoked
        assertFalse(registry.hasPermissions(game1, assetContract, attributes));

        // Now game2 should be able to get these permissions
        registry.grantAssetPermission(game2, assetContract, attributes);
        assertTrue(registry.hasPermissions(game2, assetContract, attributes));
    }

    function testGetAttributeOwner() public {
        // Grant permission
        bytes32[] memory attributes = new bytes32[](1);
        attributes[0] = HEALTH_ATTR;
        registry.grantAssetPermission(game1, assetContract, attributes);

        // Check owner
        address assetOwner = registry.getAttributeOwner(assetContract, HEALTH_ATTR);
        assertEq(assetOwner, game1);

        // Check non-existent attribute
        address noOwner = registry.getAttributeOwner(assetContract, ARMOR_ATTR);
        assertEq(noOwner, address(0));
    }

    function test_RevertWhen_RevokeUnregisteredPermission() public {
        // Try to revoke a permission that wasn't granted
        vm.expectRevert();
        registry.revokeAssetPermission(game1, assetContract);
    }

    function test_RevertWhen_AccessControl() public {
        // Test that only owner can register games and grant permissions
        vm.prank(user);

        bytes32[] memory attributes = new bytes32[](1);
        attributes[0] = HEALTH_ATTR;

        // Should fail because caller is not owner
        vm.expectRevert();
        registry.grantAssetPermission(game1, assetContract, attributes);
    }
}
