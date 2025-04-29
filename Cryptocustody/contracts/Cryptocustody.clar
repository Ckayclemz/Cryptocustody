;; CryptoCustody  
;; summary: A decentralized smart contract for time-locked crypto asset transfers upon owner inactivity

;; Constants
(define-constant admin tx-sender)
(define-constant err-only-admin (err u100))
(define-constant err-no-vault (err u101))
(define-constant err-not-allowed (err u102))
(define-constant err-vault-exists (err u103))
(define-constant err-still-active (err u104))
(define-constant err-not-enough-approvals (err u105))
(define-constant err-too-many-assets (err u106))
(define-constant err-invalid-principal (err u107))
(define-constant err-self-registration (err u108))

;; Data Maps
(define-map account-storage
  { account: principal }
  {
    assets: (list 100 principal),
    beneficiaries: (list 5 principal),
    dormancy-period: uint,
    activity-timestamp: uint,
    required-confirmations: uint
  }
)

(define-map trustee-registry
  { account: principal, trustee: principal }
  { authorized: bool }
)

(define-map disbursement-requests
  { account: principal }
  {
    request-time: uint,
    confirmations: (list 5 principal)
  }
)

;; Private Helpers
(define-private (is-account-holder (user principal))
  (is-eq tx-sender user)
)

(define-private (current-time)
  stacks-block-height
)

(define-private (check-dormancy (vault-data {
                               assets: (list 100 principal),
                               beneficiaries: (list 5 principal),
                               dormancy-period: uint,
                               activity-timestamp: uint,
                               required-confirmations: uint
                             }))
  (> (- (current-time) (get activity-timestamp vault-data)) (get dormancy-period vault-data))
)

(define-private (validate-account (account-to-check principal))
  (match (map-get? account-storage { account: account-to-check })
    account-data true
    false
  )
)

(define-private (validate-trustee (trustee-to-check principal))
  ;; Prevent self-registration and perform other validations as needed
  (not (is-eq trustee-to-check tx-sender))
)

;; Public Functions
(define-public (create-account (beneficiaries (list 5 principal)) (dormancy-period uint) (required-confirmations uint))
  (let ((account-data {
          assets: (list ),
          beneficiaries: beneficiaries,
          dormancy-period: dormancy-period,
          activity-timestamp: (current-time),
          required-confirmations: required-confirmations
        }))
    (asserts! (is-none (map-get? account-storage { account: tx-sender })) err-vault-exists)
    (ok (map-set account-storage { account: tx-sender } account-data))
  )
)

(define-public (deposit-asset (token principal))
  (let ((account-data (unwrap! (map-get? account-storage { account: tx-sender }) err-no-vault)))
    (let ((updated-assets (unwrap! (as-max-len? (append (get assets account-data) token) u100) err-too-many-assets)))
      (ok (map-set account-storage
        { account: tx-sender }
        (merge account-data {
          assets: updated-assets,
          activity-timestamp: (current-time)
        })
      ))
    )
  )
)

(define-public (check-in)
  (let ((account-data (unwrap! (map-get? account-storage { account: tx-sender }) err-no-vault)))
    (ok (map-set account-storage
      { account: tx-sender }
      (merge account-data { activity-timestamp: (current-time) })
    ))
  )
)

(define-public (register-trustee (trustee principal))
  (begin
    ;; Validate the trustee is not the same as the account holder
    (asserts! (validate-trustee trustee) err-self-registration)
    
    ;; Check if the account exists
    (let ((account-data (unwrap! (map-get? account-storage { account: tx-sender }) err-no-vault)))
      (ok (map-set trustee-registry
        { account: tx-sender, trustee: trustee }
        { authorized: true }
      ))
    )
  )
)

(define-public (initiate-disbursement (account principal))
  (begin
    ;; Validate the account exists
    (asserts! (validate-account account) err-no-vault)
    
    (let ((account-data (unwrap! (map-get? account-storage { account: account }) err-no-vault)))
      (asserts! (check-dormancy account-data) err-still-active)
      (ok (map-set disbursement-requests
        { account: account }
        {
          request-time: (current-time),
          confirmations: (list tx-sender)
        }
      ))
    )
  )
)

(define-public (confirm-disbursement (account principal))
  (begin
    ;; Validate the account exists
    (asserts! (validate-account account) err-no-vault)
    
    (let (
      (account-data (unwrap! (map-get? account-storage { account: account }) err-no-vault))
      (request-data (unwrap! (map-get? disbursement-requests { account: account }) err-no-vault))
      (trustee-status (default-to { authorized: false } (map-get? trustee-registry { account: account, trustee: tx-sender })))
    )
      (asserts! (get authorized trustee-status) err-not-allowed)
      (asserts! (check-dormancy account-data) err-still-active)
      (let ((updated-confirmations (unwrap! (as-max-len? (append (get confirmations request-data) tx-sender) u5) err-not-enough-approvals)))
        (ok (map-set disbursement-requests
          { account: account }
          (merge request-data { confirmations: updated-confirmations })
        ))
      )
    )
  )
)

(define-public (execute-disbursement (account principal))
  (begin
    ;; Validate the account exists
    (asserts! (validate-account account) err-no-vault)
    
    (let (
      (account-data (unwrap! (map-get? account-storage { account: account }) err-no-vault))
      (request-data (unwrap! (map-get? disbursement-requests { account: account }) err-no-vault))
    )
      (asserts! (check-dormancy account-data) err-still-active)
      (asserts! (>= (len (get confirmations request-data)) (get required-confirmations account-data)) err-not-enough-approvals)
      
      ;; Since we've validated the account, we can safely delete the records
      (map-delete account-storage { account: account })
      (map-delete disbursement-requests { account: account })
      (ok true)
    )
  )
)

;; Read-only Functions
(define-read-only (get-account-info (account principal))
  (begin
    ;; Validate the account exists
    (asserts! (validate-account account) err-no-vault)
    (ok (unwrap! (map-get? account-storage { account: account }) err-no-vault))
  )
)

(define-read-only (get-request-status (account principal))
  (begin
    ;; Validate the account exists
    (asserts! (validate-account account) err-no-vault)
    (ok (unwrap! (map-get? disbursement-requests { account: account }) err-no-vault))
  )
)