# Remix Demo Script — Academic Credential Smart Contracts

## Demo Goal

The goal is to prove that:

1. An accreditation body can approve a university issuer.
2. An approved university can mint a credential NFT to a graduate.
3. The credential stores a document hash on-chain.
4. Anyone can verify the credential using the stored hash.
5. The issuer can revoke a credential without deleting its history.

---
| Account   | Role               |
| --------- | ------------------ |
| Account 1 | Accreditation Body |
| Account 2 | University         |
| Account 3 | Graduate           |
| Account 4 | Employer           |


**Demo Setup**

Compiled:

IssuerRegistry.sol
CredentialNFT.sol

Step 1 — Deploy the Issuer Registry

Select:

IssuerRegistry

Deploy it from:

Account 1

Explanation

This contract represents the trusted issuer registry. In the real system, this would be controlled by an accreditation body such as a government or education authority.

The deployer automatically becomes the contract owner through OpenZeppelin’s Ownable contract.

After deployment, copy the deployed IssuerRegistry contract address.

**Step 2 — Deploy the Credential NFT Contract**

Select:

CredentialNFT

In the constructor input, paste the deployed IssuerRegistry address.

Deploy it from:

Account 1
Explanation

The credential contract needs the registry address so it can check whether the caller is an approved university before allowing credentials to be minted, updated, or revoked.

CredentialNFT communicates directly with IssuerRegistry using:

issuerRegistry.isIssuer(msg.sender)

This demonstrates direct smart contract interaction.

**Step 3 — Approve the University Issuer**

Stay on:

Account 1

Open the deployed IssuerRegistry contract.

Call:

addIssuer(Account2Address)
Explanation

This simulates the accreditation body approving a university wallet address.

Only approved issuer addresses can create credentials.

To confirm it worked, call:

isIssuer(Account2Address)
Expected Result
true

**Step 4 — Mint a Credential to a Graduate**

Copy:

Account3Address

Switch to:

Account 2

(approved university)

Open the deployed CredentialNFT contract.

Call:

mintCredential(
    Account3Address,
    0xabcafd16e1aadac29d57b0fe2a2ff0515e9d91ec0b7fd54f6c69acbfa8a44aeb
)
Explanation

Account 2 is acting as the approved university.

Account 3 is the graduate receiving the credential NFT.

The hexadecimal value represents the keccak256 hash of the original academic PDF.

When mintCredential() is called, CredentialNFT internally calls:

issuerRegistry.isIssuer(msg.sender)

to confirm the university is approved before allowing minting.

Expected Result
Transaction succeeds
Token ID 0 is created
Account 3 becomes the owner of the NFT

Optional check:

ownerOf(0)
Expected Result
Account3Address

**Step 5 — Read the Credential Record**

Call:

getCredential(0)
Expected Result
documentHash matches stored hash
issuer matches Account 2
valid = true
Explanation

The blockchain now stores:

the credential hash,
the issuing university,
and whether the credential is currently valid.

Only the hash is stored on-chain — not the original PDF.

**Step 6 — Verify the Credential**

Call:

verifyCredential(
    0,
    0xabcafd16e1aadac29d57b0fe2a2ff0515e9d91ec0b7fd54f6c69acbfa8a44aeb
)
Expected Result
true
Explanation

This simulates an employer hashing the graduate’s PDF locally and checking whether that hash matches the on-chain credential record.

Now test an incorrect hash:

verifyCredential(
    0,
    0x2222222222222222222222222222222222222222222222222222222222222222
)
Expected Result
false
Explanation

If the PDF has been modified or forged, the hash changes completely, so verification fails.

**Step 7 — Revoke the Credential**

Stay on:

Account 2

Call:

revokeCredential(0)
Expected Result
Transaction succeeds
Credential validity changes to false

Now call:

getCredential(0)
Expected Result
valid = false

Then call:

verifyCredential(
    0,
    0xabcafd16e1aadac29d57b0fe2a2ff0515e9d91ec0b7fd54f6c69acbfa8a44aeb
)
Expected Result
false
Explanation

The credential history still exists on-chain, but the credential is no longer considered valid.

This preserves auditability while allowing universities to revoke credentials if required.

**Step 8 — Demonstrate Soulbound Behaviour**

Switch to:

Account 3

(graduate)

Attempt to transfer the credential:

safeTransferFrom(Account3Address, Account4Address, 0)
Expected Result
Transaction reverted: Credentials are non-transferable
Explanation

Academic credentials should remain tied to the original graduate and should not be transferable between users.

The contract overrides ERC-721 transfer behaviour to create a soulbound credential NFT.

**Step 9 — Demonstrate Access Control**

Switch to:

Account 4

(unapproved address)

Try calling:

mintCredential(
    Account3Address,
    0x1111111111111111111111111111111111111111111111111111111111111111
)
Expected Result
Transaction reverted: Not approved issuer
Explanation

This proves that unapproved addresses cannot issue fake credentials.

Only universities approved through IssuerRegistry are permitted to mint, revoke, or update credentials.
