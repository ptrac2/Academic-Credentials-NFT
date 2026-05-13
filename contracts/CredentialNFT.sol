// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IIssuerRegistry {
    function isIssuer(address issuer) external view returns (bool);
}

/**
 * @title CredentialNFT
 * @dev ERC-721 academic credential system.
 * Stores only document hashes on-chain, not full PDFs.
 */
contract CredentialNFT is ERC721 {
    IIssuerRegistry public issuerRegistry;

    uint256 private nextTokenId;

    struct Credential {
        bytes32 documentHash;
        address issuer;
        bool valid;
    }

    mapping(uint256 => Credential) private credentials;

    event CredentialMinted(
        uint256 indexed tokenId,
        address indexed graduate,
        address indexed issuer,
        bytes32 documentHash
    );

    event CredentialRevoked(
        uint256 indexed tokenId,
        address indexed issuer
    );

    event CredentialUpdated(
        uint256 indexed tokenId,
        address indexed issuer,
        bytes32 newDocumentHash
    );

    /**
     * @dev Links this contract to the issuer registry.
     */
    constructor(address registryAddress) ERC721("Academic Credential", "ACRED") {
        require(registryAddress != address(0), "Invalid registry address");
        issuerRegistry = IIssuerRegistry(registryAddress);
    }

    /**
     * @dev Only approved universities can call issuer-only functions.
     */
    modifier onlyIssuer() {
        require(issuerRegistry.isIssuer(msg.sender), "Not approved issuer");
        _;
    }

    /**
     * @dev Only the original issuing university can modify its own credential.
     */
    modifier onlyOriginalIssuer(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Credential does not exist");
        require(credentials[tokenId].issuer == msg.sender, "Not original issuer");
        _;
    }

    /**
     * @dev Mints a new academic credential NFT to a graduate.
     * The PDF itself remains off-chain; only its keccak256 hash is stored.
     */
    function mintCredential(
        address graduate,
        bytes32 documentHash
    ) external onlyIssuer returns (uint256) {
        require(graduate != address(0), "Invalid graduate address");
        require(documentHash != bytes32(0), "Invalid document hash");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        credentials[tokenId] = Credential({
            documentHash: documentHash,
            issuer: msg.sender,
            valid: true
        });

        _safeMint(graduate, tokenId);

        emit CredentialMinted(tokenId, graduate, msg.sender, documentHash);

        return tokenId;
    }

    /**
     * @dev Revokes a credential without deleting its history.
     * This is better than burning because verification history remains auditable.
     */
    function revokeCredential(
        uint256 tokenId
    ) external onlyIssuer onlyOriginalIssuer(tokenId) {
        require(credentials[tokenId].valid, "Credential already revoked");

        credentials[tokenId].valid = false;

        emit CredentialRevoked(tokenId, msg.sender);
    }

    /**
     * @dev Updates the stored document hash if a credential PDF needs correction.
     */
    function updateCredentialHash(
        uint256 tokenId,
        bytes32 newDocumentHash
    ) external onlyIssuer onlyOriginalIssuer(tokenId) {
        require(credentials[tokenId].valid, "Credential revoked");
        require(newDocumentHash != bytes32(0), "Invalid document hash");

        credentials[tokenId].documentHash = newDocumentHash;

        emit CredentialUpdated(tokenId, msg.sender, newDocumentHash);
    }

    /**
     * @dev Returns the credential's hash, issuer, and validity status.
     */
    function getCredential(
        uint256 tokenId
    )
        external
        view
        returns (
            bytes32 documentHash,
            address issuer,
            bool valid
        )
    {
        require(_ownerOf(tokenId) != address(0), "Credential does not exist");

        Credential memory credential = credentials[tokenId];

        return (
            credential.documentHash,
            credential.issuer,
            credential.valid
        );
    }

    /**
     * @dev Simple verification helper.
     * Employer can hash the PDF locally, then compare it against this function.
     */
    function verifyCredential(
        uint256 tokenId,
        bytes32 providedHash
    ) external view returns (bool) {
        require(_ownerOf(tokenId) != address(0), "Credential does not exist");

        Credential memory credential = credentials[tokenId];

        return credential.valid && credential.documentHash == providedHash;
    }

    /**
     * @dev Makes the credential soulbound.
     * Allows minting, blocks normal transfers.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);

        if (from != address(0) && to != address(0)) {
            revert("Credentials are non-transferable");
        }

        return super._update(to, tokenId, auth);
    }
}