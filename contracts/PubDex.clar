;; PubDex - Decentralized Data Indexing and Verification Platform
;; Contract: PubDex
;; Description: A platform for submitting, verifying, and rewarding quality data indexes
;; Version: 1.0.0

;; Core data structures
(define-data-var next-index-id uint u1)
(define-map indexes uint (tuple 
  (data-hash (buff 32)) 
  (metadata (buff 256)) 
  (owner principal)
  (verified bool)
  (verification-count uint)
  (created-at uint)
  (category (buff 32))
))

(define-map rewards principal uint)
(define-constant max-metadata-size u256)
(define-constant base-reward-amount u100)

;; Governance
(define-data-var admin principal tx-sender)
(define-map approved-providers principal bool)

;; Reputation System
(define-map provider-reputation principal (tuple
  (score uint)
  (total-submissions uint)
  (verified-submissions uint)
  (flags-received uint)
  (last-updated uint)
))

(define-constant reputation-decay-period u144) ;; ~1 day in blocks
(define-constant max-reputation-score u1000)
(define-constant min-reputation-score u100)

;; Dynamic Economic Model
(define-map category-demand (buff 32) uint)
(define-map provider-tier principal uint) ;; 1=bronze, 2=silver, 3=gold
(define-constant tier-multipliers (list u100 u150 u200)) ;; 1x, 1.5x, 2x rewards

;; Data Verification System
(define-map verification-requests uint (tuple
  (index-id uint)
  (verifiers (list 5 principal))
  (confirmations uint)
  (required-confirmations uint)
  (deadline uint)
))

(define-data-var next-verification-id uint u1)
(define-map verifier-votes (tuple (verification-id uint) (verifier principal)) bool)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-FORBIDDEN (err u403))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INSUFFICIENT-STAKE (err u405))
(define-constant ERR-INSUFFICIENT-STAKE-BALANCE (err u406))
(define-constant ERR-INVALID-INPUT (err u407))
(define-constant ERR-INVALID-AMOUNT (err u408))
(define-constant ERR-EMPTY-METADATA (err u409))
(define-constant ERR-EMPTY-HASH (err u410))
(define-constant ERR-VERIFICATION-FAILED (err u411))
(define-constant ERR-ALREADY-VERIFIED (err u412))
(define-constant ERR-VERIFICATION-EXPIRED (err u413))

;; Helper functions for min/max operations
(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

(define-private (max-uint (a uint) (b uint))
  (if (>= a b) a b)
)

;; Input validation helpers
(define-private (is-valid-principal (p principal))
  (not (is-eq p 'SP000000000000000000002Q6VF78))
)

(define-private (is-valid-amount (amount uint))
  (and (> amount u0) (<= amount u1000000000))
)

(define-private (is-valid-metadata (metadata (buff 256)))
  (and (> (len metadata) u0) (<= (len metadata) max-metadata-size))
)

(define-private (is-valid-hash (hash (buff 32)))
  (is-eq (len hash) u32)
)

(define-private (is-valid-category (category (buff 32)))
  (and (> (len category) u0) (<= (len category) u32))
)

;; Modifiers
(define-private (is-admin (sender principal))
  (is-eq sender (var-get admin))
)

(define-private (is-approved-provider (provider principal))
  (default-to false (map-get? approved-providers provider))
)

;; Reputation System Functions
(define-private (get-provider-reputation (provider principal))
  (default-to 
    {score: min-reputation-score, total-submissions: u0, verified-submissions: u0, flags-received: u0, last-updated: u0}
    (map-get? provider-reputation provider)
  )
)

(define-private (update-reputation (provider principal) (score-change int) (submission-verified bool))
  (let ((current-rep (get-provider-reputation provider))
        (new-score (if (> score-change 0)
                     (min-uint (+ (get score current-rep) (to-uint score-change)) max-reputation-score)
                     (max-uint (- (get score current-rep) (to-uint (- 0 score-change))) min-reputation-score)))
        (new-total (+ (get total-submissions current-rep) u1))
        (new-verified (if submission-verified 
                        (+ (get verified-submissions current-rep) u1)
                        (get verified-submissions current-rep))))
    (map-set provider-reputation provider {
      score: new-score,
      total-submissions: new-total,
      verified-submissions: new-verified,
      flags-received: (get flags-received current-rep),
      last-updated: stacks-block-height
    })
  )
)

(define-private (calculate-reputation-multiplier (provider principal))
  (let ((rep (get-provider-reputation provider)))
    (if (>= (get score rep) u800) u150  ;; 1.5x for high reputation
        (if (>= (get score rep) u600) u125  ;; 1.25x for medium reputation
            u100))  ;; 1x for low reputation
  )
)

;; Dynamic Economic Model Functions
(define-private (get-provider-tier (provider principal))
  (default-to u1 (map-get? provider-tier provider))
)

(define-private (calculate-dynamic-reward (provider principal) (category (buff 32)))
  (let ((base-reward base-reward-amount)
        (tier (get-provider-tier provider))
        (tier-multiplier (unwrap-panic (element-at tier-multipliers (- tier u1))))
        (reputation-multiplier (calculate-reputation-multiplier provider))
        (demand-multiplier (+ u100 (default-to u0 (map-get? category-demand category)))))
    (/ (* (* (* base-reward tier-multiplier) reputation-multiplier) demand-multiplier) u10000)
  )
)

(define-private (update-category-demand (category (buff 32)))
  (map-set category-demand category 
    (min-uint (+ (default-to u0 (map-get? category-demand category)) u10) u200))
)

;; Data Verification Functions
(define-private (create-verification-request (index-id uint) (verifiers (list 5 principal)))
  (let ((verification-id (var-get next-verification-id)))
    (map-set verification-requests verification-id {
      index-id: index-id,
      verifiers: verifiers,
      confirmations: u0,
      required-confirmations: u3,
      deadline: (+ stacks-block-height u144) ;; 1 day deadline
    })
    (var-set next-verification-id (+ verification-id u1))
    verification-id
  )
)

;; Admin Functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal new-admin) ERR-INVALID-INPUT)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (approve-provider (provider principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (map-set approved-providers provider true)
    (ok true)
  )
)

(define-public (revoke-provider (provider principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (map-delete approved-providers provider)
    (ok true)
  )
)

(define-public (set-provider-tier (provider principal) (tier uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (asserts! (and (>= tier u1) (<= tier u3)) ERR-INVALID-INPUT)
    (map-set provider-tier provider tier)
    (ok true)
  )
)

;; Core PubDex Platform Functions
(define-public (submit-index (data-hash (buff 32)) (metadata (buff 256)) (category (buff 32)))
  (let ((id (var-get next-index-id))
        (reward (calculate-dynamic-reward tx-sender category)))
    (begin
      (asserts! (is-approved-provider tx-sender) ERR-FORBIDDEN)
      (asserts! (is-valid-hash data-hash) ERR-EMPTY-HASH)
      (asserts! (is-valid-metadata metadata) ERR-EMPTY-METADATA)
      (asserts! (is-valid-category category) ERR-INVALID-INPUT)
      
      (map-set indexes id {
        data-hash: data-hash,
        metadata: metadata,
        owner: tx-sender,
        verified: false,
        verification-count: u0,
        created-at: stacks-block-height,
        category: category
      })
      
      (var-set next-index-id (+ id u1))
      (map-set rewards tx-sender (+ reward (default-to u0 (map-get? rewards tx-sender))))
      (update-reputation tx-sender 10 false)
      (update-category-demand category)
      
      (print {event: "pubdex-submit-index", index-id: id, provider: tx-sender, category: category})
      (print {event: "pubdex-reward-distributed", provider: tx-sender, amount: reward})
      (ok id)
    )
  )
)

(define-public (update-index (index-id uint) (metadata (buff 256)))
  (begin
    (asserts! (> index-id u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-metadata metadata) ERR-EMPTY-METADATA)
    (match (map-get? indexes index-id)
      some-index
        (begin
          (asserts! (is-eq (get owner some-index) tx-sender) ERR-FORBIDDEN)
          (map-set indexes index-id (merge some-index {metadata: metadata}))
          (print {event: "pubdex-update-index", index-id: index-id})
          (ok true)
        )
      ERR-NOT-FOUND
    )
  )
)

;; PubDex Verification System
(define-public (request-verification (index-id uint) (verifiers (list 5 principal)))
  (begin
    (asserts! (> index-id u0) ERR-INVALID-INPUT)
    (match (map-get? indexes index-id)
      some-index
        (begin
          (asserts! (is-eq (get owner some-index) tx-sender) ERR-FORBIDDEN)
          (asserts! (not (get verified some-index)) ERR-ALREADY-VERIFIED)
          (let ((verification-id (create-verification-request index-id verifiers)))
            (print {event: "pubdex-verification-requested", index-id: index-id, verification-id: verification-id})
            (ok verification-id)
          )
        )
      ERR-NOT-FOUND
    )
  )
)

(define-public (verify-index (verification-id uint) (approve bool))
  (begin
    (asserts! (> verification-id u0) ERR-INVALID-INPUT)
    (match (map-get? verification-requests verification-id)
      some-request
        (begin
          (asserts! (< stacks-block-height (get deadline some-request)) ERR-VERIFICATION-EXPIRED)
          (asserts! (is-some (index-of (get verifiers some-request) tx-sender)) ERR-FORBIDDEN)
          
          (map-set verifier-votes {verification-id: verification-id, verifier: tx-sender} approve)
          
          (if approve
            (let ((new-confirmations (+ (get confirmations some-request) u1)))
              (map-set verification-requests verification-id 
                (merge some-request {confirmations: new-confirmations}))
              
              (if (>= new-confirmations (get required-confirmations some-request))
                (begin
                  (match (map-get? indexes (get index-id some-request))
                    some-index
                      (begin
                        (map-set indexes (get index-id some-request) 
                          (merge some-index {verified: true, verification-count: (+ (get verification-count some-index) u1)}))
                        (update-reputation (get owner some-index) 50 true)
                        (print {event: "pubdex-index-verified", index-id: (get index-id some-request)})
                        (ok true)
                      )
                    ERR-NOT-FOUND
                  )
                )
                (ok true)
              )
            )
            (ok true)
          )
        )
      ERR-NOT-FOUND
    )
  )
)

;; Read-only functions
(define-read-only (get-index (index-id uint))
  (begin
    (asserts! (> index-id u0) ERR-INVALID-INPUT)
    (match (map-get? indexes index-id)
      some-index (ok some-index)
      ERR-NOT-FOUND
    )
  )
)

(define-read-only (get-reward-balance (provider principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? rewards provider)))
  )
)

(define-read-only (get-reputation (provider principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (ok (get-provider-reputation provider))
  )
)

(define-read-only (get-verification-request (verification-id uint))
  (begin
    (asserts! (> verification-id u0) ERR-INVALID-INPUT)
    (match (map-get? verification-requests verification-id)
      some-request (ok some-request)
      ERR-NOT-FOUND
    )
  )
)

(define-read-only (get-category-demand (category (buff 32)))
  (begin
    (asserts! (is-valid-category category) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? category-demand category)))
  )
)

(define-public (withdraw-rewards)
  (let ((amount (default-to u0 (map-get? rewards tx-sender))))
    (begin
      (asserts! (> amount u0) ERR-INSUFFICIENT-BALANCE)
      (map-delete rewards tx-sender)
      (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
      (ok amount)
    )
  )
)

;; PubDex Staking System
(define-map stakes principal uint)
(define-constant min-stake u1000)

(define-public (stake (amount uint))
  (begin
    (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT)
    (asserts! (>= amount min-stake) ERR-INSUFFICIENT-STAKE)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set stakes tx-sender (+ amount (default-to u0 (map-get? stakes tx-sender))))
    (ok true)
  )
)

(define-read-only (get-stake (staker principal))
  (begin
    (asserts! (is-valid-principal staker) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? stakes staker)))
  )
)

;; PubDex Flagging System
(define-map flags uint uint)

(define-public (flag-index (index-id uint))
  (begin
    (asserts! (> index-id u0) ERR-INVALID-INPUT)
    (match (map-get? indexes index-id)
      some-index
        (begin
          (map-set flags index-id (+ u1 (default-to u0 (map-get? flags index-id))))
          ;; Decrease reputation of index owner when flagged
          (update-reputation (get owner some-index) -5 false)
          (let ((current-rep (get-provider-reputation (get owner some-index))))
            (map-set provider-reputation (get owner some-index)
              (merge current-rep {flags-received: (+ (get flags-received current-rep) u1)}))
          )
          (print {event: "pubdex-index-flagged", index-id: index-id, flags: (+ u1 (default-to u0 (map-get? flags index-id)))})
          (ok true)
        )
      ERR-NOT-FOUND
    )
  )
)

(define-read-only (get-flags (index-id uint))
  (begin
    (asserts! (> index-id u0) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? flags index-id)))
  )
)

;; Admin penalty system
(define-public (slash-provider (provider principal) (amount uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT)
    (let ((current-stake (default-to u0 (map-get? stakes provider))))
      (if (>= current-stake amount)
        (begin
          (map-set stakes provider (- current-stake amount))
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (update-reputation provider -100 false)
          (print {event: "pubdex-provider-slashed", provider: provider, amount: amount})
          (ok true)
        )
        ERR-INSUFFICIENT-STAKE-BALANCE
      )
    )
  )
)

;; Future PubDex extension placeholder
(define-public (register-external-source (source-url (buff 128)))
  (begin
    (asserts! (> (len source-url) u0) ERR-INVALID-INPUT)
    (asserts! (<= (len source-url) u128) ERR-INVALID-INPUT)
    (ok true)
  )
)