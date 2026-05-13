// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IssuerRegistry
 * @dev Stores the list of approved universities/issuers.
 * The owner represents the accreditation body.
 */
contract IssuerRegistry is Ownable {
    mapping(address => bool) private approvedIssuers;

    event IssuerAdded(address indexed issuer);
    event IssuerRemoved(address indexed issuer);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Accreditation body adds a university as an approved issuer.
     */
    function addIssuer(address issuer) external onlyOwner {
        require(issuer != address(0), "Invalid issuer address");
        require(!approvedIssuers[issuer], "Issuer already approved");

        approvedIssuers[issuer] = true;
        emit IssuerAdded(issuer);
    }

    /**
     * @dev Accreditation body removes a university's issuing rights.
     */
    function removeIssuer(address issuer) external onlyOwner {
        require(approvedIssuers[issuer], "Issuer not approved");

        approvedIssuers[issuer] = false;
        emit IssuerRemoved(issuer);
    }

    /**
     * @dev Public read function used by CredentialNFT.
     */
    function isIssuer(address issuer) external view returns (bool) {
        return approvedIssuers[issuer];
    }
}