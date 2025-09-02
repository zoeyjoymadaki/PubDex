;; PubDex - Decentralized Data Indexing and Verification Platform
;; Contract: PubDex Enhanced
;; Description: A platform for submitting, verifying, and rewarding quality data indexes
;; Version: 2.1.0 - Enhanced with Economic Incentive Alignment and Anti-Gaming Mechanisms

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

;; Enhanced Reputation System with Time Decay and Quality Tracking
(define-map provider-reputation principal (tuple
  (score uint)
  (total-submissions uint)
  (verified-submissions uint)
  (flags-received uint)
  (last-updated uint)
  (quality-score uint)
  (consistency-score uint)
))

;; Category-specific expertise tracking
(define-map category-expertise (tuple (provider principal) (category (buff 32))) (tuple
  (submissions uint)
  (verified-submissions uint)
  (quality-average uint)
  (last-activity uint)
))

;; Time-weighted reputation history (last 10 entries)
(define-map reputation-history principal (list 10 (tuple
  (score uint)
  (timestamp uint)
  (quality uint)
  (category (buff 32))
)))

(define-constant reputation-decay-period u144) ;; ~1 day in blocks
(define-constant max-reputation-score u1000)
(define-constant min-reputation-score u100)
(define-constant decay-rate u5) ;; 5% decay per period
(define-constant quality-weight u30) ;; 30% weight for quality in reputation

;; Economic Security Framework
(define-constant minimum-economic-security u1000000) ;; 1M STX minimum total stake
(define-data-var total-staked uint u0)
(define-data-var insurance-fund uint u0)

;; NEW: Verifier Economic Stake System
(define-map verifier-stakes principal uint)
(define-map verifier-performance principal (tuple
  (correct-verifications uint)
  (total-verifications uint)
  (stake-slashed uint)
  (reputation-score uint)
))

(define-constant min-verifier-stake u5000) ;; Higher stake requirement for verifiers
(define-constant verifier-slash-rate u20) ;; 20% slash for incorrect verifications

;; NEW: Anti-collusion tracking
(define-map provider-verifier-interactions (tuple (provider principal) (verifier principal)) (tuple
  (interaction-count uint)
  (success-rate uint)
  (last-interaction uint)
))

(define-constant max-interaction-rate u30) ;; Max 30% of verifications from same verifier
(define-constant collusion-threshold u80) ;; 80%+ success rate triggers investigation

;; NEW: Sybil attack prevention
(define-map identity-verification principal (tuple
  (verification-method (buff 32))
  (verification-hash (buff 32))
  (verified-at uint)
  (verification-score uint)
))

;; Status constants as buffers
(define-constant STATUS-PENDING (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "pending")) u16)))
(define-constant STATUS-VALIDATED (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "validated")) u16)))
(define-constant STATUS-REJECTED (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "rejected")) u16)))

;; Category constants as buffers
(define-constant CATEGORY-PENALTY (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "penalty")) u32)))
(define-constant CATEGORY-ADMIN-PENALTY (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "admin-penalty")) u32)))

;; Evidence type constants as buffers
(define-constant EVIDENCE-FALSE-VERIFICATION (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "false-verification")) u32)))
(define-constant EVIDENCE-SPAM-SUBMISSION (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "spam-submission")) u32)))
(define-constant EVIDENCE-COLLUSION (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "collusion")) u32)))
(define-constant EVIDENCE-DATA-MANIPULATION (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? "data-manipulation")) u32)))

;; Slashing evidence and conditions
(define-data-var next-evidence-id uint u1)
(define-map slashing-evidence uint (tuple
  (accused principal)
  (evidence-type (buff 32))
  (evidence-hash (buff 32))
  (reporter principal)
  (stake-at-risk uint)
  (challenge-deadline uint)
  (status (buff 16))
  (validator-votes uint)
  (required-votes uint)
))

(define-map evidence-validators principal bool)
(define-map validator-votes (tuple (evidence-id uint) (validator principal)) bool)

;; Slashing conditions with penalties
(define-constant slashing-conditions (list 
  {condition: "false-verification", penalty: u50}
  {condition: "spam-submission", penalty: u25}
  {condition: "collusion", penalty: u100}
  {condition: "data-manipulation", penalty: u75}
))

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
(define-constant ERR-INSUFFICIENT-ECONOMIC-SECURITY (err u414))
(define-constant ERR-EVIDENCE-EXPIRED (err u415))
(define-constant ERR-ALREADY-VOTED (err u416))
(define-constant ERR-POTENTIAL-COLLUSION (err u417))
(define-constant ERR-INSUFFICIENT-VERIFIER-STAKE (err u418))

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

(define-private (is-evidence-validator (validator principal))
  (default-to false (map-get? evidence-validators validator))
)

;; NEW: Check if principal is a qualified verifier
(define-private (is-qualified-verifier (verifier principal))
  (let ((verifier-stake (default-to u0 (map-get? verifier-stakes verifier))))
    (>= verifier-stake min-verifier-stake)
  )
)

;; Enhanced Reputation System Functions
(define-private (get-provider-reputation (provider principal))
  (default-to 
    {score: min-reputation-score, total-submissions: u0, verified-submissions: u0, 
     flags-received: u0, last-updated: u0, quality-score: u500, consistency-score: u500}
    (map-get? provider-reputation provider)
  )
)

(define-private (calculate-time-decay (last-updated uint) (current-score uint))
  (let ((blocks-passed (- stacks-block-height last-updated))
        (decay-periods (/ blocks-passed reputation-decay-period)))
    (if (> decay-periods u0)
      (let ((decay-amount (/ (* current-score (* decay-rate decay-periods)) u100)))
        (max-uint (- current-score decay-amount) min-reputation-score))
      current-score)
  )
)

(define-private (calculate-quality-score (provider principal) (category (buff 32)) (verification-success bool))
  (let ((expertise (default-to {submissions: u0, verified-submissions: u0, quality-average: u500, last-activity: u0}
                               (map-get? category-expertise {provider: provider, category: category})))
        (base-quality (if verification-success u800 u200))
        (experience-bonus (min-uint (/ (get submissions expertise) u10) u100))
        (consistency-bonus (if (> (get verified-submissions expertise) u5) u50 u0)))
    (min-uint (+ base-quality experience-bonus consistency-bonus) u1000)
  )
)

(define-private (update-enhanced-reputation (provider principal) (score-change int) (submission-verified bool) (category (buff 32)))
  (let ((current-rep (get-provider-reputation provider))
        (decayed-score (calculate-time-decay (get last-updated current-rep) (get score current-rep)))
        (quality-score (calculate-quality-score provider category submission-verified))
        (new-base-score (if (> score-change 0)
                          (min-uint (+ decayed-score (to-uint score-change)) max-reputation-score)
                          (max-uint (- decayed-score (to-uint (- 0 score-change))) min-reputation-score)))
        (quality-weighted-score (/ (+ (* new-base-score (- u100 quality-weight)) (* quality-score quality-weight)) u100))
        (new-total (+ (get total-submissions current-rep) u1))
        (new-verified (if submission-verified 
                        (+ (get verified-submissions current-rep) u1)
                        (get verified-submissions current-rep)))
        (consistency-score (if (> new-total u0) (/ (* new-verified u1000) new-total) u0)))
    
    ;; Update main reputation
    (map-set provider-reputation provider {
      score: quality-weighted-score,
      total-submissions: new-total,
      verified-submissions: new-verified,
      flags-received: (get flags-received current-rep),
      last-updated: stacks-block-height,
      quality-score: quality-score,
      consistency-score: consistency-score
    })
    
    ;; Update category expertise
    (let ((current-expertise (default-to {submissions: u0, verified-submissions: u0, quality-average: u500, last-activity: u0}
                                        (map-get? category-expertise {provider: provider, category: category}))))
      (map-set category-expertise {provider: provider, category: category} {
        submissions: (+ (get submissions current-expertise) u1),
        verified-submissions: (if submission-verified 
                                (+ (get verified-submissions current-expertise) u1)
                                (get verified-submissions current-expertise)),
        quality-average: (/ (+ (get quality-average current-expertise) quality-score) u2),
        last-activity: stacks-block-height
      })
    )
    
    ;; Update reputation history
    (let ((current-history (default-to (list) (map-get? reputation-history provider)))
          (new-entry {score: quality-weighted-score, timestamp: stacks-block-height, quality: quality-score, category: category}))
      (map-set reputation-history provider 
        (unwrap-panic (as-max-len? (append current-history new-entry) u10)))
    )
  )
)

(define-private (calculate-reputation-multiplier (provider principal))
  (let ((rep (get-provider-reputation provider))
        (decayed-score (calculate-time-decay (get last-updated rep) (get score rep))))
    (if (>= decayed-score u800) u150  ;; 1.5x for high reputation
        (if (>= decayed-score u600) u125  ;; 1.25x for medium reputation
            u100))  ;; 1x for low reputation
  )
)

;; Economic Security Functions
(define-private (check-economic-security)
  (>= (var-get total-staked) minimum-economic-security)
)

(define-private (calculate-dynamic-stake-requirement (provider principal))
  (let ((rep (get-provider-reputation provider))
        (tier (get-provider-tier provider))
        (base-requirement u1000))
    (if (< (get score rep) u300)
      (* base-requirement u3) ;; 3x stake for low reputation
      (if (is-eq tier u3)
        (/ base-requirement u2) ;; 0.5x stake for gold tier
        base-requirement))
  )
)

;; NEW: Verifier Economic Stake Functions
(define-public (stake-as-verifier (amount uint))
  (begin
    (asserts! (>= amount min-verifier-stake) ERR-INSUFFICIENT-STAKE)
    (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set verifier-stakes tx-sender (+ amount (default-to u0 (map-get? verifier-stakes tx-sender))))
    
    ;; Initialize verifier performance tracking
    (map-set verifier-performance tx-sender {
      correct-verifications: u0,
      total-verifications: u0,
      stake-slashed: u0,
      reputation-score: u500
    })
    (print {event: "verifier-staked", verifier: tx-sender, amount: amount})
    (ok true)
  )
)

;; NEW: Slash verifier for incorrect verification
(define-private (slash-verifier (verifier principal) (slash-amount uint))
  (let ((current-stake (default-to u0 (map-get? verifier-stakes verifier)))
        (performance (default-to {correct-verifications: u0, total-verifications: u0, stake-slashed: u0, reputation-score: u500}
                                (map-get? verifier-performance verifier))))
    (begin
      (map-set verifier-stakes verifier (- current-stake slash-amount))
      (map-set verifier-performance verifier 
        (merge performance {
          stake-slashed: (+ (get stake-slashed performance) slash-amount),
          reputation-score: (max-uint (- (get reputation-score performance) u100) u0)
        }))
      (var-set insurance-fund (+ (var-get insurance-fund) slash-amount))
      (print {event: "verifier-slashed", verifier: verifier, amount: slash-amount})
    )
  )
)

;; NEW: Check for potential collusion
(define-private (check-collusion (provider principal) (verifier principal))
  (let ((interaction-key {provider: provider, verifier: verifier})
        (current-interactions (default-to {interaction-count: u0, success-rate: u0, last-interaction: u0}
                                         (map-get? provider-verifier-interactions interaction-key))))
    (and (> (get interaction-count current-interactions) u5)
         (> (get success-rate current-interactions) collusion-threshold))
  )
)

;; NEW: Update interaction tracking
(define-private (update-interaction-tracking (provider principal) (verifier principal) (approve bool))
  (let ((interaction-key {provider: provider, verifier: verifier})
        (current-interactions (default-to {interaction-count: u0, success-rate: u0, last-interaction: u0}
                                         (map-get? provider-verifier-interactions interaction-key)))
        (new-count (+ (get interaction-count current-interactions) u1))
        (current-successes (/ (* (get success-rate current-interactions) (get interaction-count current-interactions)) u100))
        (new-successes (if approve (+ current-successes u1) current-successes))
        (new-success-rate (if (> new-count u0) (/ (* new-successes u100) new-count) u0)))
    (map-set provider-verifier-interactions interaction-key {
      interaction-count: new-count,
      success-rate: new-success-rate,
      last-interaction: stacks-block-height
    })
  )
)

;; NEW: Identity verification for Sybil prevention
(define-public (submit-identity-verification (verification-method (buff 32)) (verification-hash (buff 32)))
  (begin
    (asserts! (> (len verification-method) u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-hash verification-hash) ERR-INVALID-INPUT)
    
    (map-set identity-verification tx-sender {
      verification-method: verification-method,
      verification-hash: verification-hash,
      verified-at: stacks-block-height,
      verification-score: u0 ;; To be updated by admin after verification
    })
    (print {event: "identity-verification-submitted", provider: tx-sender})
    (ok true)
  )
)

;; NEW: Admin function to confirm identity verification
(define-public (confirm-identity-verification (provider principal) (score uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (asserts! (<= score u1000) ERR-INVALID-INPUT)
    
    (match (map-get? identity-verification provider)
      some-verification
        (begin
          (map-set identity-verification provider 
            (merge some-verification {verification-score: score}))
          (print {event: "identity-verification-confirmed", provider: provider, score: score})
          (ok true)
        )
      ERR-NOT-FOUND
    )
  )
)

(define-public (submit-slashing-evidence (accused principal) (evidence-type (buff 32)) (evidence-hash (buff 32)))
  (let ((evidence-id (var-get next-evidence-id))
        (accused-stake (default-to u0 (map-get? stakes accused))))
    (begin
      (asserts! (is-valid-principal accused) ERR-INVALID-INPUT)
      (asserts! (> (len evidence-type) u0) ERR-INVALID-INPUT)
      (asserts! (is-valid-hash evidence-hash) ERR-INVALID-INPUT)
      (asserts! (> accused-stake u0) ERR-INSUFFICIENT-STAKE-BALANCE)
      
      (map-set slashing-evidence evidence-id {
        accused: accused,
        evidence-type: evidence-type,
        evidence-hash: evidence-hash,
        reporter: tx-sender,
        stake-at-risk: accused-stake,
        challenge-deadline: (+ stacks-block-height u1008), ;; 7 days
        status: STATUS-PENDING,
        validator-votes: u0,
        required-votes: u3
      })
      
      (var-set next-evidence-id (+ evidence-id u1))
      (print {event: "slashing-evidence-submitted", evidence-id: evidence-id, accused: accused})
      (ok evidence-id)
    )
  )
)

(define-public (validate-slashing-evidence (evidence-id uint) (approve bool))
  (begin
    (asserts! (is-evidence-validator tx-sender) ERR-UNAUTHORIZED)
    (asserts! (> evidence-id u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? validator-votes {evidence-id: evidence-id, validator: tx-sender})) ERR-ALREADY-VOTED)
    
    (match (map-get? slashing-evidence evidence-id)
      some-evidence
        (begin
          (asserts! (< stacks-block-height (get challenge-deadline some-evidence)) ERR-EVIDENCE-EXPIRED)
          (asserts! (is-eq (get status some-evidence) STATUS-PENDING) ERR-INVALID-INPUT)
          
          (map-set validator-votes {evidence-id: evidence-id, validator: tx-sender} approve)
          
          (if approve
            (let ((new-votes (+ (get validator-votes some-evidence) u1)))
              (map-set slashing-evidence evidence-id 
                (merge some-evidence {validator-votes: new-votes}))
              
              (if (>= new-votes (get required-votes some-evidence))
                (begin
                  (map-set slashing-evidence evidence-id 
                    (merge some-evidence {status: STATUS-VALIDATED}))
                  (unwrap-panic (execute-slashing (get accused some-evidence) (get evidence-type some-evidence)))
                  (print {event: "slashing-executed", evidence-id: evidence-id, accused: (get accused some-evidence)})
                  (ok true)
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

(define-private (execute-slashing (accused principal) (evidence-type (buff 32)))
  (let ((penalty-rate (if (is-eq evidence-type EVIDENCE-FALSE-VERIFICATION) u50
                        (if (is-eq evidence-type EVIDENCE-SPAM-SUBMISSION) u25
                          (if (is-eq evidence-type EVIDENCE-COLLUSION) u100
                            (if (is-eq evidence-type EVIDENCE-DATA-MANIPULATION) u75
                              u25))))) ;; default penalty
        (current-stake (default-to u0 (map-get? stakes accused)))
        (slash-amount (/ (* current-stake penalty-rate) u100)))
    (begin
      (map-set stakes accused (- current-stake slash-amount))
      (var-set total-staked (- (var-get total-staked) slash-amount))
      (var-set insurance-fund (+ (var-get insurance-fund) slash-amount))
      (update-enhanced-reputation accused (- 0 100) false CATEGORY-PENALTY)
      (ok true)
    )
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

(define-public (add-evidence-validator (validator principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal validator) ERR-INVALID-INPUT)
    (map-set evidence-validators validator true)
    (ok true)
  )
)

(define-public (remove-evidence-validator (validator principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-valid-principal validator) ERR-INVALID-INPUT)
    (map-delete evidence-validators validator)
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
      (asserts! (check-economic-security) ERR-INSUFFICIENT-ECONOMIC-SECURITY)
      
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
      (update-enhanced-reputation tx-sender 10 false category)
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

;; NEW: Enhanced verification with economic consequences and collusion detection
(define-public (verify-index (verification-id uint) (approve bool))
  (begin
    (asserts! (> verification-id u0) ERR-INVALID-INPUT)
    (asserts! (is-qualified-verifier tx-sender) ERR-INSUFFICIENT-VERIFIER-STAKE)
    
    (match (map-get? verification-requests verification-id)
      some-request
        (begin
          (asserts! (< stacks-block-height (get deadline some-request)) ERR-VERIFICATION-EXPIRED)
          (asserts! (is-some (index-of (get verifiers some-request) tx-sender)) ERR-FORBIDDEN)
          
          ;; Check for potential collusion
          (match (map-get? indexes (get index-id some-request))
            some-index
              (let ((provider (get owner some-index)))
                (begin
                  ;; Update interaction tracking
                  (update-interaction-tracking provider tx-sender approve)
                  
                  ;; Check for collusion and warn if detected
                  (begin
  (if (check-collusion provider tx-sender)
    (begin
      (print {event: "potential-collusion-detected", provider: provider, verifier: tx-sender})
      true
    )
    true
  )
)
                  
                  ;; Update verifier performance
                  (let ((current-performance (default-to {correct-verifications: u0, total-verifications: u0, stake-slashed: u0, reputation-score: u500}
                                                        (map-get? verifier-performance tx-sender))))
                    (map-set verifier-performance tx-sender 
                      (merge current-performance {
                        total-verifications: (+ (get total-verifications current-performance) u1)
                      }))
                  )
                  
                  (map-set verifier-votes {verification-id: verification-id, verifier: tx-sender} approve)
                  
                  (if approve
                    (let ((new-confirmations (+ (get confirmations some-request) u1)))
                      (map-set verification-requests verification-id 
                        (merge some-request {confirmations: new-confirmations}))
                      
                      (if (>= new-confirmations (get required-confirmations some-request))
                        (begin
                          (map-set indexes (get index-id some-request) 
                            (merge some-index {verified: true, verification-count: (+ (get verification-count some-index) u1)}))
                          (update-enhanced-reputation provider 50 true (get category some-index))
                          
                          ;; Update verifier performance for correct verification
                          (let ((current-performance (default-to {correct-verifications: u0, total-verifications: u0, stake-slashed: u0, reputation-score: u500}
                                                                (map-get? verifier-performance tx-sender))))
                            (map-set verifier-performance tx-sender 
                              (merge current-performance {
                                correct-verifications: (+ (get correct-verifications current-performance) u1),
                                reputation-score: (min-uint (+ (get reputation-score current-performance) u10) u1000)
                              }))
                          )
                          
                          (print {event: "pubdex-index-verified", index-id: (get index-id some-request)})
                          (ok true)
                        )
                        (ok true)
                      )
                    )
                    (ok true)
                  )
                )
              )
            ERR-NOT-FOUND
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
    (let ((rep (get-provider-reputation provider)))
      (ok (merge rep {score: (calculate-time-decay (get last-updated rep) (get score rep))}))
    )
  )
)

(define-read-only (get-category-expertise (provider principal) (category (buff 32)))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (asserts! (is-valid-category category) ERR-INVALID-INPUT)
    (ok (default-to {submissions: u0, verified-submissions: u0, quality-average: u500, last-activity: u0}
                   (map-get? category-expertise {provider: provider, category: category})))
  )
)

(define-read-only (get-reputation-history (provider principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (ok (default-to (list) (map-get? reputation-history provider)))
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

(define-read-only (get-slashing-evidence (evidence-id uint))
  (begin
    (asserts! (> evidence-id u0) ERR-INVALID-INPUT)
    (match (map-get? slashing-evidence evidence-id)
      some-evidence (ok some-evidence)
      ERR-NOT-FOUND
    )
  )
)

(define-read-only (get-economic-security-status)
  (ok {
    total-staked: (var-get total-staked),
    minimum-required: minimum-economic-security,
    security-ratio: (if (> minimum-economic-security u0) 
                      (/ (* (var-get total-staked) u100) minimum-economic-security) 
                      u0),
    insurance-fund: (var-get insurance-fund)
  })
)

;; NEW: Read-only functions for enhanced features
(define-read-only (get-verifier-performance (verifier principal))
  (begin
    (asserts! (is-valid-principal verifier) ERR-INVALID-INPUT)
    (ok (default-to {correct-verifications: u0, total-verifications: u0, stake-slashed: u0, reputation-score: u500}
                   (map-get? verifier-performance verifier)))
  )
)

(define-read-only (get-interaction-history (provider principal) (verifier principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (asserts! (is-valid-principal verifier) ERR-INVALID-INPUT)
    (ok (default-to {interaction-count: u0, success-rate: u0, last-interaction: u0}
                   (map-get? provider-verifier-interactions {provider: provider, verifier: verifier})))
  )
)

(define-read-only (get-identity-verification (provider principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (ok (map-get? identity-verification provider))
  )
)

(define-read-only (get-verifier-stake (verifier principal))
  (begin
    (asserts! (is-valid-principal verifier) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? verifier-stakes verifier)))
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

;; Enhanced Staking System with Dynamic Requirements
(define-map stakes principal uint)
(define-constant min-stake u1000)

(define-public (stake (amount uint))
  (let ((required-stake (calculate-dynamic-stake-requirement tx-sender)))
    (begin
      (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT)
      (asserts! (>= amount required-stake) ERR-INSUFFICIENT-STAKE)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set stakes tx-sender (+ amount (default-to u0 (map-get? stakes tx-sender))))
      (var-set total-staked (+ (var-get total-staked) amount))
      (ok true)
    )
  )
)

(define-read-only (get-stake (staker principal))
  (begin
    (asserts! (is-valid-principal staker) ERR-INVALID-INPUT)
    (ok (default-to u0 (map-get? stakes staker)))
  )
)

(define-read-only (get-required-stake (provider principal))
  (begin
    (asserts! (is-valid-principal provider) ERR-INVALID-INPUT)
    (ok (calculate-dynamic-stake-requirement provider))
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
          (update-enhanced-reputation (get owner some-index) -5 false (get category some-index))
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
          (var-set total-staked (- (var-get total-staked) amount))
          (var-set insurance-fund (+ (var-get insurance-fund) amount))
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (update-enhanced-reputation provider -100 false CATEGORY-ADMIN-PENALTY)
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
