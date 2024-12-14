// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGameAsset is IERC721 {
    /**
     * @notice Get attributes for a token
     * @param tokenId Token ID to query
     * @param attributeTypes Array of attribute types to get
     * @return Array of attribute values
     */
    function getAttributes(uint256 tokenId, bytes32[] calldata attributeTypes) external view returns (bytes[] memory);

    /**
     * @notice Update attributes for a token
     * @param tokenId Token ID to update
     * @param attributeTypes Array of attribute types to update
     * @param values Array of corresponding values
     */
    function updateAttributes(uint256 tokenId, bytes32[] calldata attributeTypes, bytes[] calldata values) external;
}
