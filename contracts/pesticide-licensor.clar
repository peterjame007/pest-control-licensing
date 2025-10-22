;; pesticide-licensor
;; Manages pest control licenses with pesticide usage tracking and safety compliance

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-expired (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-amount (err u104))

(define-data-var next-license-id uint u1)
(define-data-var next-application-id uint u1)
(define-data-var total-licenses uint u0)

(define-map licenses
  { license-id: uint }
  {
    applicator: principal,
    applicator-name: (string-utf8 100),
    license-type: (string-ascii 50),
    certification-level: (string-ascii 30),
    issue-date: uint,
    expiration-date: uint,
    active: bool,
    renewal-count: uint
  }
)

(define-map pesticide-usage
  { license-id: uint, application-id: uint }
  {
    pesticide-name: (string-ascii 100),
    application-site: (string-utf8 200),
    amount-used: uint,
    application-date: uint,
    weather-conditions: (string-ascii 100),
    safety-equipment-used: (string-utf8 200)
  }
)

(define-map training-records
  { license-id: uint }
  {
    training-hours: uint,
    last-training-date: uint,
    certifications: (string-utf8 300)
  }
)

(define-map violations
  { license-id: uint, violation-id: uint }
  {
    violation-type: (string-ascii 100),
    description: (string-utf8 300),
    violation-date: uint,
    penalty-amount: uint,
    resolved: bool
  }
)

(define-read-only (get-license (license-id uint))
  (map-get? licenses { license-id: license-id })
)

(define-read-only (get-usage-record (license-id uint) (application-id uint))
  (map-get? pesticide-usage { license-id: license-id, application-id: application-id })
)

(define-read-only (get-training-record (license-id uint))
  (map-get? training-records { license-id: license-id })
)

(define-read-only (get-violation (license-id uint) (violation-id uint))
  (map-get? violations { license-id: license-id, violation-id: violation-id })
)

(define-read-only (is-license-valid (license-id uint) (current-height uint))
  (match (map-get? licenses { license-id: license-id })
    license (ok (and (get active license) (< current-height (get expiration-date license))))
    err-not-found
  )
)

(define-read-only (get-total-licenses)
  (ok (var-get total-licenses))
)

(define-public (issue-license
    (applicator principal)
    (applicator-name (string-utf8 100))
    (license-type (string-ascii 50))
    (certification-level (string-ascii 30))
  )
  (let ((license-id (var-get next-license-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set licenses
      { license-id: license-id }
      {
        applicator: applicator,
        applicator-name: applicator-name,
        license-type: license-type,
        certification-level: certification-level,
        issue-date: burn-block-height,
        expiration-date: (+ burn-block-height u52560),
        active: true,
        renewal-count: u0
      })
    (var-set next-license-id (+ license-id u1))
    (var-set total-licenses (+ (var-get total-licenses) u1))
    (ok license-id))
)

(define-public (renew-license (license-id uint))
  (let ((license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get applicator license)) err-unauthorized)
    (map-set licenses
      { license-id: license-id }
      (merge license {
        expiration-date: (+ burn-block-height u52560),
        renewal-count: (+ (get renewal-count license) u1)
      }))
    (ok true))
)

(define-public (record-pesticide-application
    (license-id uint)
    (application-id uint)
    (pesticide-name (string-ascii 100))
    (application-site (string-utf8 200))
    (amount-used uint)
    (weather-conditions (string-ascii 100))
    (safety-equipment-used (string-utf8 200))
  )
  (let ((license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get applicator license)) err-unauthorized)
    (asserts! (> amount-used u0) err-invalid-amount)
    (map-set pesticide-usage
      { license-id: license-id, application-id: application-id }
      {
        pesticide-name: pesticide-name,
        application-site: application-site,
        amount-used: amount-used,
        application-date: burn-block-height,
        weather-conditions: weather-conditions,
        safety-equipment-used: safety-equipment-used
      })
    (var-set next-application-id (+ (var-get next-application-id) u1))
    (ok true))
)

(define-public (update-training-record
    (license-id uint)
    (training-hours uint)
    (certifications (string-utf8 300))
  )
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set training-records
      { license-id: license-id }
      {
        training-hours: training-hours,
        last-training-date: burn-block-height,
        certifications: certifications
      })
    (ok true))
)

(define-public (report-violation
    (license-id uint)
    (violation-id uint)
    (violation-type (string-ascii 100))
    (description (string-utf8 300))
    (penalty-amount uint)
  )
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set violations
      { license-id: license-id, violation-id: violation-id }
      {
        violation-type: violation-type,
        description: description,
        violation-date: burn-block-height,
        penalty-amount: penalty-amount,
        resolved: false
      })
    (ok true))
)

(define-public (resolve-violation (license-id uint) (violation-id uint))
  (let ((violation (unwrap! (map-get? violations { license-id: license-id, violation-id: violation-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set violations
      { license-id: license-id, violation-id: violation-id }
      (merge violation { resolved: true }))
    (ok true))
)

(define-public (suspend-license (license-id uint))
  (let ((license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set licenses
      { license-id: license-id }
      (merge license { active: false }))
    (ok true))
)

(define-public (reactivate-license (license-id uint))
  (let ((license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set licenses
      { license-id: license-id }
      (merge license { active: true }))
    (ok true))
)
