// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title BaseGameImplementation
 * @dev Enhanced abstract contract for game-specific implementations with built-in governance and upgrade mechanisms
 */
abstract contract GameImplementation is ReentrancyGuard, Pausable, AccessControl {
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Asset registry
    mapping(bytes32 => address) public assetContracts;
    mapping(address => bytes32[]) public allowedAttributes;
    bytes32[] public supportedAssetTypes;

    // Attribute constraints
    mapping(bytes32 => uint256) public attributeMaxValues;
    mapping(bytes32 => uint256) public attributeMinValues;
    mapping(bytes32 => uint256) public attributeUpdateCooldowns;

    // Upgrade system
    struct UpgradeProposal {
        address sourceGame;
        uint256 tokenId;
        bytes32[] attributes;
        bytes[] values;
        uint256 proposalTime;
        bool executed;
        mapping(address => bool) approvals;
        uint256 approvalCount;
    }

    mapping(bytes32 => UpgradeProposal) public upgradeProposals;
    uint256 public requiredApprovals;
    uint256 public proposalTimeout;
    uint256 public updateTimelock;

    // Rate limiting
    mapping(address => uint256) public lastUpdateTime;
    uint256 public globalUpdateCooldown;

    // Version control
    uint256 public constant VERSION = 1;
    mapping(bytes32 => uint256) public attributeVersions;

    // Events
    event AssetContractRegistered(bytes32 indexed assetType, address indexed assetContract);
    event AssetContractRemoved(bytes32 indexed assetType, address indexed assetContract);
    event AttributeConstraintsSet(bytes32 indexed attributeType, uint256 minValue, uint256 maxValue, uint256 cooldown);
    event UpgradeProposed(bytes32 indexed proposalId, address indexed sourceGame, uint256 tokenId);
    event UpgradeApproved(bytes32 indexed proposalId, address indexed approver);
    event UpgradeExecuted(bytes32 indexed proposalId, uint256 tokenId);
    event AttributeVersionUpdated(bytes32 indexed attributeType, uint256 version);

    constructor(uint256 _requiredApprovals, uint256 _proposalTimeout, uint256 _updateTimelock) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        requiredApprovals = _requiredApprovals;
        proposalTimeout = _proposalTimeout;
        updateTimelock = _updateTimelock;
        globalUpdateCooldown = 1 hours; // Default 1 hour cooldown
    }

    /**
     * @notice Register a new asset contract with constraints
     * @param assetType Type of the asset
     * @param assetContract Address of the asset contract
     * @param attributes Allowed attributes
     * @param minValues Minimum values for attributes
     * @param maxValues Maximum values for attributes
     * @param cooldowns Update cooldowns for attributes
     */
    function registerAssetContract(
        bytes32 assetType,
        address assetContract,
        bytes32[] memory attributes,
        uint256[] memory minValues,
        uint256[] memory maxValues,
        uint256[] memory cooldowns
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(assetContract != address(0), "Invalid asset contract");
        require(assetContracts[assetType] == address(0), "Asset type already registered");
        require(
            attributes.length == minValues.length && attributes.length == maxValues.length
                && attributes.length == cooldowns.length,
            "Array lengths mismatch"
        );

        assetContracts[assetType] = assetContract;
        allowedAttributes[assetContract] = attributes;
        supportedAssetTypes.push(assetType);

        // Set constraints for each attribute
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeMinValues[attributes[i]] = minValues[i];
            attributeMaxValues[attributes[i]] = maxValues[i];
            attributeUpdateCooldowns[attributes[i]] = cooldowns[i];
            attributeVersions[attributes[i]] = 1; // Initialize version
        }

        emit AssetContractRegistered(assetType, assetContract);
    }

    /**
     * @notice Propose an upgrade from another game's attributes
     * @param sourceGame Source game address
     * @param tokenId Token ID to upgrade
     * @param attributes Attributes to upgrade
     * @param values New values for attributes
     */
    function proposeUpgrade(address sourceGame, uint256 tokenId, bytes32[] memory attributes, bytes[] memory values)
        external
        whenNotPaused
        nonReentrant
        returns (bytes32)
    {
        require(attributes.length == values.length, "Arrays length mismatch");
        require(lastUpdateTime[msg.sender] + globalUpdateCooldown <= block.timestamp, "Global cooldown not elapsed");

        bytes32 proposalId = keccak256(abi.encodePacked(sourceGame, tokenId, block.timestamp, msg.sender));

        UpgradeProposal storage proposal = upgradeProposals[proposalId];
        proposal.sourceGame = sourceGame;
        proposal.tokenId = tokenId;
        proposal.attributes = attributes;
        proposal.values = values;
        proposal.proposalTime = block.timestamp;
        proposal.executed = false;
        proposal.approvalCount = 0;

        lastUpdateTime[msg.sender] = block.timestamp;

        emit UpgradeProposed(proposalId, sourceGame, tokenId);
        return proposalId;
    }

    /**
     * @notice Approve an upgrade proposal
     * @param proposalId ID of the proposal
     */
    function approveUpgrade(bytes32 proposalId) external onlyRole(UPGRADER_ROLE) {
        UpgradeProposal storage proposal = upgradeProposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.proposalTime + proposalTimeout > block.timestamp, "Proposal expired");
        require(!proposal.approvals[msg.sender], "Already approved");

        proposal.approvals[msg.sender] = true;
        proposal.approvalCount++;

        emit UpgradeApproved(proposalId, msg.sender);

        if (proposal.approvalCount >= requiredApprovals) {
            _executeUpgrade(proposalId);
        }
    }

    /**
     * @notice Update attribute version
     * @param attributeType Attribute to update
     * @param newVersion New version number
     */
    function updateAttributeVersion(bytes32 attributeType, uint256 newVersion) external onlyRole(GOVERNANCE_ROLE) {
        require(newVersion > attributeVersions[attributeType], "Version must increase");
        attributeVersions[attributeType] = newVersion;
        emit AttributeVersionUpdated(attributeType, newVersion);
    }

    /**
     * @notice Set global update cooldown
     * @param newCooldown New cooldown period
     */
    function setGlobalUpdateCooldown(uint256 newCooldown) external onlyRole(GOVERNANCE_ROLE) {
        globalUpdateCooldown = newCooldown;
    }

    /**
     * @notice Emergency pause
     */
    function pause() external onlyRole(GOVERNANCE_ROLE) {
        _pause();
    }

    /**
     * @notice Resume operations
     */
    function unpause() external onlyRole(GOVERNANCE_ROLE) {
        _unpause();
    }

    /**
     * @dev Internal function to execute upgrade
     * @param proposalId Proposal ID to execute
     */
    function _executeUpgrade(bytes32 proposalId) internal {
        UpgradeProposal storage proposal = upgradeProposals[proposalId];

        // Validate all values are within constraints
        for (uint256 i = 0; i < proposal.attributes.length; i++) {
            bytes memory value = proposal.values[i];
            bytes32 attr = proposal.attributes[i];

            require(_validateAttributeValue(attr, value), "Invalid attribute value");
        }

        // Encode and update attributes
        bytes memory encodedAttributes = _encodeAttributes(proposal.attributes, proposal.values);

        // Implement your update logic here
        _updateAttributesInternal(proposal.tokenId, encodedAttributes);

        proposal.executed = true;
        emit UpgradeExecuted(proposalId, proposal.tokenId);
    }

    /**
     * @dev Validate attribute value against constraints
     * @param attributeType Attribute type
     * @param value Value to validate
     */
    function _validateAttributeValue(bytes32 attributeType, bytes memory value) internal view virtual returns (bool);

    /**
     * @dev Update attributes internally
     * @param tokenId Token ID
     * @param encodedAttributes Encoded attributes
     */
    function _updateAttributesInternal(uint256 tokenId, bytes memory encodedAttributes) internal virtual;

    /**
     * @dev Encode attributes
     */
    function _encodeAttributes(bytes32[] memory attributes, bytes[] memory values)
        internal
        pure
        virtual
        returns (bytes memory);

    /**
     * @dev Decode attributes
     */
    function _decodeAttributes(bytes memory data)
        internal
        pure
        virtual
        returns (bytes32[] memory attributes, bytes[] memory values);
}
