;; Pesticide Licensor Smart Contract
;; Manages pest control licenses with pesticide usage tracking and safety compliance

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-expired (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-suspended (err u106))
(define-constant err-revoked (err u107))

;; License status constants
(define-constant status-active u1)
(define-constant status-expired u2)
(define-constant status-suspended u3)
(define-constant status-revoked u4)

;; Data Variables
(define-data-var license-counter uint u0)
(define-data-var application-counter uint u0)
(define-data-var violation-counter uint u0)

;; Data Maps
(define-map licenses
  { license-id: uint }
  {
    applicator: principal,
    issued-date: uint,
    expiration-date: uint,
    status: uint,
    license-type: (string-ascii 50),
    certifications: (string-ascii 200),
    issuing-department: principal
  }
)

(define-map applicator-licenses
  { applicator: principal }
  { license-id: uint }
)

(define-map pesticide-applications
  { application-id: uint }
  {
    license-id: uint,
    applicator: principal,
    application-date: uint,
    location: (string-ascii 200),
    pesticide-type: (string-ascii 100),
    quantity: uint,
    target-pest: (string-ascii 100),
    area-treated: uint
  }
)

(define-map usage-stats
  { license-id: uint }
  {
    total-applications: uint,
    total-quantity-used: uint,
    last-application-date: uint
  }
)

(define-map violations
  { violation-id: uint }
  {
    license-id: uint,
    applicator: principal,
    violation-date: uint,
    violation-type: (string-ascii 100),
    description: (string-ascii 300),
    severity: uint
  }
)

(define-map violation-history
  { license-id: uint }
  { total-violations: uint, suspended-count: uint }
)

(define-map authorized-departments
  { department: principal }
  { authorized: bool, department-name: (string-ascii 100) }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-authorized-department)
  (default-to false (get authorized (map-get? authorized-departments { department: tx-sender })))
)

;; Public Functions

;; Authorize a department to issue licenses
(define-public (authorize-department (department principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-set authorized-departments
      { department: department }
      { authorized: true, department-name: name }
    ))
  )
)

;; Revoke department authorization
(define-public (revoke-department (department principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-set authorized-departments
      { department: department }
      { authorized: false, department-name: "" }
    ))
  )
)

;; Issue a new pesticide applicator license
(define-public (issue-license 
  (applicator principal)
  (expiration-date uint)
  (license-type (string-ascii 50))
  (certifications (string-ascii 200)))
  (let
    (
      (new-license-id (+ (var-get license-counter) u1))
      (existing-license (map-get? applicator-licenses { applicator: applicator }))
    )
    (asserts! (is-authorized-department) err-unauthorized)
    (asserts! (is-none existing-license) err-already-exists)
    (asserts! (> expiration-date stacks-block-height) err-invalid-input)
    
    (map-set licenses
      { license-id: new-license-id }
      {
        applicator: applicator,
        issued-date: stacks-block-height,
        expiration-date: expiration-date,
        status: status-active,
        license-type: license-type,
        certifications: certifications,
        issuing-department: tx-sender
      }
    )
    
    (map-set applicator-licenses
      { applicator: applicator }
      { license-id: new-license-id }
    )
    
    (map-set usage-stats
      { license-id: new-license-id }
      { total-applications: u0, total-quantity-used: u0, last-application-date: u0 }
    )
    
    (map-set violation-history
      { license-id: new-license-id }
      { total-violations: u0, suspended-count: u0 }
    )
    
    (var-set license-counter new-license-id)
    (ok new-license-id)
  )
)

;; Renew an existing license
(define-public (renew-license (license-id uint) (new-expiration-date uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
    )
    (asserts! (is-authorized-department) err-unauthorized)
    (asserts! (> new-expiration-date stacks-block-height) err-invalid-input)
    (asserts! (is-eq (get status license) status-active) err-revoked)
    
    (ok (map-set licenses
      { license-id: license-id }
      (merge license { expiration-date: new-expiration-date, status: status-active })
    ))
  )
)

;; Suspend a license
(define-public (suspend-license (license-id uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
      (history (unwrap! (map-get? violation-history { license-id: license-id }) err-not-found))
    )
    (asserts! (is-authorized-department) err-unauthorized)
    
    (map-set licenses
      { license-id: license-id }
      (merge license { status: status-suspended })
    )
    
    (ok (map-set violation-history
      { license-id: license-id }
      (merge history { suspended-count: (+ (get suspended-count history) u1) })
    ))
  )
)

;; Revoke a license permanently
(define-public (revoke-license (license-id uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
    )
    (asserts! (is-authorized-department) err-unauthorized)
    
    (ok (map-set licenses
      { license-id: license-id }
      (merge license { status: status-revoked })
    ))
  )
)

;; Record a pesticide application
(define-public (record-application
  (license-id uint)
  (location (string-ascii 200))
  (pesticide-type (string-ascii 100))
  (quantity uint)
  (target-pest (string-ascii 100))
  (area-treated uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
      (stats (unwrap! (map-get? usage-stats { license-id: license-id }) err-not-found))
      (new-application-id (+ (var-get application-counter) u1))
    )
    (asserts! (is-eq (get applicator license) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status license) status-active) err-suspended)
    (asserts! (> (get expiration-date license) stacks-block-height) err-expired)
    
    (map-set pesticide-applications
      { application-id: new-application-id }
      {
        license-id: license-id,
        applicator: tx-sender,
        application-date: stacks-block-height,
        location: location,
        pesticide-type: pesticide-type,
        quantity: quantity,
        target-pest: target-pest,
        area-treated: area-treated
      }
    )
    
    (map-set usage-stats
      { license-id: license-id }
      {
        total-applications: (+ (get total-applications stats) u1),
        total-quantity-used: (+ (get total-quantity-used stats) quantity),
        last-application-date: stacks-block-height
      }
    )
    
    (var-set application-counter new-application-id)
    (ok new-application-id)
  )
)

;; Record a violation
(define-public (record-violation
  (license-id uint)
  (violation-type (string-ascii 100))
  (description (string-ascii 300))
  (severity uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
      (history (unwrap! (map-get? violation-history { license-id: license-id }) err-not-found))
      (new-violation-id (+ (var-get violation-counter) u1))
    )
    (asserts! (is-authorized-department) err-unauthorized)
    
    (map-set violations
      { violation-id: new-violation-id }
      {
        license-id: license-id,
        applicator: (get applicator license),
        violation-date: stacks-block-height,
        violation-type: violation-type,
        description: description,
        severity: severity
      }
    )
    
    (map-set violation-history
      { license-id: license-id }
      (merge history { total-violations: (+ (get total-violations history) u1) })
    )
    
    (var-set violation-counter new-violation-id)
    (ok new-violation-id)
  )
)

;; Read-only Functions

;; Get license details
(define-read-only (get-license (license-id uint))
  (ok (map-get? licenses { license-id: license-id }))
)

;; Get license by applicator
(define-read-only (get-license-by-applicator (applicator principal))
  (ok (map-get? applicator-licenses { applicator: applicator }))
)

;; Check if license is valid
(define-read-only (is-license-valid (license-id uint))
  (match (map-get? licenses { license-id: license-id })
    license (ok (and 
      (is-eq (get status license) status-active)
      (> (get expiration-date license) stacks-block-height)
    ))
    (ok false)
  )
)

;; Get application record
(define-read-only (get-application-record (application-id uint))
  (ok (map-get? pesticide-applications { application-id: application-id }))
)

;; Get usage statistics
(define-read-only (get-usage-stats (license-id uint))
  (ok (map-get? usage-stats { license-id: license-id }))
)

;; Get violation history
(define-read-only (get-violation-history (license-id uint))
  (ok (map-get? violation-history { license-id: license-id }))
)

;; Get violation details
(define-read-only (get-violation (violation-id uint))
  (ok (map-get? violations { violation-id: violation-id }))
)

;; Check if department is authorized
(define-read-only (is-department-authorized (department principal))
  (ok (default-to false (get authorized (map-get? authorized-departments { department: department }))))
)

;; Get total licenses issued
(define-read-only (get-total-licenses)
  (ok (var-get license-counter))
)

;; Get total applications recorded
(define-read-only (get-total-applications)
  (ok (var-get application-counter))
)

;; Get total violations recorded
(define-read-only (get-total-violations)
  (ok (var-get violation-counter))
)

