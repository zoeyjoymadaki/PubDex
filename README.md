# PubDex Smart Contract v2.0.0

**PubDex** is a decentralized data indexing and verification platform built on Clarity, now enhanced with advanced reputation tracking and economic security mechanisms.

---

## New Features in v2.0.0

### Enhanced Reputation System
- **Time Decay**: 5% reputation decay per day (~144 blocks)
- **Quality Scoring**: 30% weight in reputation calculation
- **Category Expertise**: Tracks provider performance in specific categories
- **Consistency Tracking**: Rewards consistent quality submissions
- **Historical Data**: Maintains last 10 reputation entries per provider

### Economic Security Framework
- **Minimum Security**: 1M STX minimum total stake requirement
- **Insurance Fund**: Collects slashed stakes
- **Dynamic Requirements**: Stake requirements vary based on reputation and tier

### Advanced Slashing Mechanism
- **Evidence Types**:
  - False Verification (50% penalty)
  - Spam Submission (25% penalty)
  - Collusion (100% penalty)
  - Data Manipulation (75% penalty)
- **Validator Voting**: Requires multiple validator confirmations
- **Challenge Period**: 7-day window for evidence validation

## Previous Features
- Data Indexing with metadata and categories
- Multi-verifier verification system
- Dynamic rewards based on tiers
- Provider staking and flagging
- Administrative controls

---

## Core Functions

### Reputation Management
- `update-enhanced-reputation(provider, score-change, verified, category)`
- `calculate-quality-score(provider, category, success)`
- `calculate-time-decay(last-updated, current-score)`

### Economic Security
- `submit-slashing-evidence(accused, evidence-type, evidence-hash)`
- `validate-slashing-evidence(evidence-id, approve)`
- `execute-slashing(accused, evidence-type)`

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
- `get-category-expertise(provider, category)`
- `get-reputation-history(provider)`
- `get-slashing-evidence(evidence-id)`
- `get-economic-security-status()`
- `get-required-stake(provider)`

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

---

## Data Structures

### New in v2.0.0
- **Enhanced Provider Reputation**:
  ```clarity
  (score uint)
  (total-submissions uint)
  (verified-submissions uint)
  (flags-received uint)
  (last-updated uint)
  (quality-score uint)
  (consistency-score uint)
  ```
