# Remix Demo Script — Academic Credential Smart Contracts

## Demo Goal

This demo shows the minimum working blockchain workflow for the academic credential verification system.

The goal is to prove that:

1. An accreditation body can approve a university issuer.
2. An approved university can mint a credential NFT to a graduate.
3. The credential stores a document hash on-chain.
4. Anyone can verify the credential using the stored hash.
5. The issuer can revoke a credential without deleting its history.

---

**Demo Setup**

Compiled:

IssuerRegistry.sol
CredentialNFT.sol

**Step 1 — Deploy the Issuer Registry**

Select:

IssuerRegistry

Deploy it from Account 1.

Explanation

This contract represents the trusted issuer list. In the real system, this would be controlled by an accreditation body such as a government or education authority.

_After deployment, copy the deployed IssuerRegistry contract address._

**Step 2 — Deploy the Credential NFT Contract**

Select:

CredentialNFT

_In the constructor input, paste the deployed IssuerRegistry address._

Deploy it from Account 1.

Explanation

The credential contract needs the registry address so it can check whether the caller is an approved university before allowing credentials to be minted, updated, or revoked.

**Step 3 — Approve the University Issuer**

Stay on Account 1.

Open the deployed IssuerRegistry contract.

Call:

addIssuer(Account1Address)

Explanation

This simulates the accreditation body approving a university wallet address. Only approved issuer addresses can create credentials.

To confirm it worked, call:

isIssuer(Account1Address)

Expected result:

true

**Step 4 — Mint a Credential to a Graduate**

Switch to Account 2 and copy its address.

Then switch back to Account 1.

Open the deployed CredentialNFT contract.

Call:

mintCredential(Account2Address, 0x1111111111111111111111111111111111111111111111111111111111111111)

Explanation

Account 1 is acting as the approved university. Account 2 is the graduate receiving the credential NFT. The long hexadecimal value represents the hash of the original academic PDF.

Expected Result
Transaction succeeds
Token ID 0 is created
Account 2 becomes the owner of the NFT

Optional check:

ownerOf(0)

Expected result:

Account2Address

**Step 5 — Read the Credential Record**

Call:

getCredential(0)

Expected Result
documentHash matches stored hash
issuer matches Account 1
valid = true
Explanation

The blockchain now stores the credential hash, the original issuer, and whether the credential is currently valid.

**Step 6 — Verify the Credential**

Call:

verifyCredential(0, 0x1111111111111111111111111111111111111111111111111111111111111111)

Expected result:

true

Explanation

This simulates an employer hashing the graduate’s PDF locally and checking whether that hash matches the on-chain credential record.

Now test an incorrect hash:

verifyCredential(0, 0x2222222222222222222222222222222222222222222222222222222222222222)

Expected result:

false

Explanation

If the PDF has been changed or forged, the hash will not match, so verification fails.

**Step 7 — Revoke the Credential**

Stay on Account 1.

Call:

revokeCredential(0)

Expected Result
Transaction succeeds
Credential validity changes to false

Now call:

getCredential(0)

Expected result:

valid = false

Then call:

verifyCredential(0, correctHash)

Expected result:

false

Explanation

The credential history is still visible, but it is no longer valid. This preserves auditability while allowing universities to revoke credentials if required.

**Step 8 — Demonstrate Access Control**

Switch to an account that is not approved as an issuer.

Try calling:

mintCredential(Account2Address, fakeHash)

Expected result:

Transaction reverted: Not approved issuer

Explanation

This proves that unapproved addresses cannot issue fake credentials.
