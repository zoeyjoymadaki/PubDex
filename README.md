# PubDex Smart Contract

**PubDex** is a decentralized data indexing and verification platform built on Clarity. It enables trusted data providers to submit, verify, and manage data indexes, with dynamic rewards, reputation, staking, and governance mechanisms.

---

## Features

- **Data Indexing:** Providers submit data indexes with metadata and category tags.
- **Verification System:** Indexes can be verified by a set of chosen verifiers.
- **Dynamic Rewards:** Rewards are calculated based on provider tier, reputation, and category demand.
- **Reputation System:** Providers earn or lose reputation based on submissions, verifications, and flags.
- **Staking:** Providers can stake STX tokens and may be slashed for misbehavior.
- **Flagging:** Indexes can be flagged, affecting provider reputation.
- **Governance:** Admin can approve/revoke providers and set provider tiers.
- **Extensible:** Placeholder for registering external data sources.

---

## Data Structures

- **Indexes:** Stores data hash, metadata, owner, verification status, count, timestamp, and category.
- **Rewards:** Tracks reward balances for providers.
- **Provider Reputation:** Tracks score, submissions, verified submissions, flags, and last update.
- **Category Demand:** Used for dynamic reward calculation.
- **Provider Tier:** Determines reward multipliers.
- **Verification Requests:** Manages verification workflow.
- **Stakes:** Tracks provider staking balances.
- **Flags:** Tracks number of flags per index.

---

## Core Functions

### Governance

- `set-admin(new-admin)`  
  Set a new admin for the contract.

- `approve-provider(provider)`  
  Approve a provider to submit indexes.

- `revoke-provider(provider)`  
  Revoke a provider's approval.

- `set-provider-tier(provider, tier)`  
  Set provider tier (1=bronze, 2=silver, 3=gold).

### Index Management

- `submit-index(data-hash, metadata, category)`  
  Submit a new data index.

- `update-index(index-id, metadata)`  
  Update metadata for an existing index.

### Verification

- `request-verification(index-id, verifiers)`  
  Request verification for an index.

- `verify-index(verification-id, approve)`  
  Verifier approves or rejects a verification request.

### Rewards

- `withdraw-rewards()`  
  Withdraw accumulated rewards.

### Staking

- `stake(amount)`  
  Stake STX tokens.

### Flagging

- `flag-index(index-id)`  
  Flag an index for review.

### Admin Penalty

- `slash-provider(provider, amount)`  
  Slash a provider's stake and reputation.

### Extensions

- `register-external-source(source-url)`  
  Register an external data source (future extension).

---

## Read-Only Functions

- `get-index(index-id)`  
  Get details of an index.

- `get-reward-balance(provider)`  
  Get provider's reward balance.

- `get-reputation(provider)`  
  Get provider's reputation.

- `get-verification-request(verification-id)`  
  Get details of a verification request.

- `get-category-demand(category)`  
  Get demand for a category.

- `get-stake(staker)`  
  Get staker's balance.

- `get-flags(index-id)`  
  Get number of flags for an index.

---

## Error Codes

- `ERR-UNAUTHORIZED`  
- `ERR-INSUFFICIENT-BALANCE`  
- `ERR-FORBIDDEN`  
- `ERR-NOT-FOUND`  
- `ERR-INSUFFICIENT-STAKE`  
- `ERR-INSUFFICIENT-STAKE-BALANCE`  
- `ERR-INVALID-INPUT`  
- `ERR-INVALID-AMOUNT`  
- `ERR-EMPTY-METADATA`  
- `ERR-EMPTY-HASH`  
- `ERR-VERIFICATION-FAILED`  
- `ERR-ALREADY-VERIFIED`  
- `ERR-VERIFICATION-EXPIRED`  

---

## Events

- `submit-index`
- `reward-distributed`
- `update-index`
- `verification-requested`
- `index-verified`
- `index-flagged`
- `provider-slashed`

---

## Extending

The contract includes a placeholder for registering external data sources, allowing future integration with off-chain oracles or APIs.

---

## License

This contract is provided for educational and demonstration purposes. Please review and audit before deploying to mainnet.
