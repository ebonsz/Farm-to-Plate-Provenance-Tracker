(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRODUCT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-NOT-SUPPLIER (err u104))
(define-constant ERR-INVALID-STAGE (err u105))

(define-constant STATUS-HARVESTED u1)
(define-constant STATUS-PROCESSED u2)
(define-constant STATUS-DISTRIBUTED u3)
(define-constant STATUS-DELIVERED u4)

(define-data-var product-id-nonce uint u0)
(define-data-var supplier-id-nonce uint u0)

(define-map products
    uint
    {
        name: (string-ascii 100),
        origin: (string-ascii 100),
        category: (string-ascii 50),
        harvest-date: uint,
        current-status: uint,
        current-holder: principal,
        restaurant: (optional principal),
        is-active: bool
    }
)

(define-map product-journey
    { product-id: uint, stage: uint }
    {
        holder: principal,
        location: (string-ascii 100),
        timestamp: uint,
        temperature: (optional int),
        notes: (string-ascii 200)
    }
)

(define-map suppliers
    principal
    {
        supplier-id: uint,
        name: (string-ascii 100),
        supplier-type: (string-ascii 50),
        certification: (string-ascii 100),
        is-verified: bool
    }
)

(define-map supplier-attestations
    { product-id: uint, supplier: principal }
    {
        attestation: (string-ascii 200),
        timestamp: uint,
        quality-rating: uint
    }
)

(define-map product-suppliers
    { product-id: uint, supplier-index: uint }
    principal
)

(define-map product-supplier-count
    uint
    uint
)

(define-public (register-supplier (name (string-ascii 100)) (supplier-type (string-ascii 50)) (certification (string-ascii 100)))
    (let
        (
            (new-id (+ (var-get supplier-id-nonce) u1))
        )
        (asserts! (is-none (map-get? suppliers tx-sender)) ERR-ALREADY-EXISTS)
        (map-set suppliers tx-sender {
            supplier-id: new-id,
            name: name,
            supplier-type: supplier-type,
            certification: certification,
            is-verified: false
        })
        (var-set supplier-id-nonce new-id)
        (ok new-id)
    )
)

(define-public (verify-supplier (supplier principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (match (map-get? suppliers supplier)
            supplier-data (ok (map-set suppliers supplier (merge supplier-data { is-verified: true })))
            ERR-PRODUCT-NOT-FOUND
        )
    )
)

(define-public (register-product 
    (name (string-ascii 100)) 
    (origin (string-ascii 100)) 
    (category (string-ascii 50))
    (location (string-ascii 100))
    (temperature (optional int))
    (notes (string-ascii 200))
)
    (let
        (
            (new-id (+ (var-get product-id-nonce) u1))
            (current-block stacks-block-height)
        )
        (asserts! (is-some (map-get? suppliers tx-sender)) ERR-NOT-SUPPLIER)
        (map-set products new-id {
            name: name,
            origin: origin,
            category: category,
            harvest-date: current-block,
            current-status: STATUS-HARVESTED,
            current-holder: tx-sender,
            restaurant: none,
            is-active: true
        })
        (map-set product-journey { product-id: new-id, stage: u1 } {
            holder: tx-sender,
            location: location,
            timestamp: current-block,
            temperature: temperature,
            notes: notes
        })
        (map-set product-suppliers { product-id: new-id, supplier-index: u0 } tx-sender)
        (map-set product-supplier-count new-id u1)
        (var-set product-id-nonce new-id)
        (ok new-id)
    )
)

(define-public (update-product-status 
    (product-id uint) 
    (new-status uint)
    (location (string-ascii 100))
    (temperature (optional int))
    (notes (string-ascii 200))
)
    (let
        (
            (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
            (current-block stacks-block-height)
            (stage-count (+ (get current-status product) u1))
        )
        (asserts! (get is-active product) ERR-INVALID-STATUS)
        (asserts! (or (is-eq (get current-holder product) tx-sender) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= new-status STATUS-HARVESTED) (<= new-status STATUS-DELIVERED)) ERR-INVALID-STATUS)
        (asserts! (> new-status (get current-status product)) ERR-INVALID-STAGE)
        (map-set products product-id (merge product {
            current-status: new-status,
            current-holder: tx-sender
        }))
        (map-set product-journey { product-id: product-id, stage: stage-count } {
            holder: tx-sender,
            location: location,
            timestamp: current-block,
            temperature: temperature,
            notes: notes
        })
        (ok true)
    )
)

(define-public (transfer-product (product-id uint) (new-holder principal))
    (let
        (
            (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        )
        (asserts! (is-eq (get current-holder product) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active product) ERR-INVALID-STATUS)
        (map-set products product-id (merge product { current-holder: new-holder }))
        (ok true)
    )
)

(define-public (add-supplier-attestation 
    (product-id uint) 
    (attestation (string-ascii 200))
    (quality-rating uint)
)
    (let
        (
            (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
            (supplier (unwrap! (map-get? suppliers tx-sender) ERR-NOT-SUPPLIER))
            (current-block stacks-block-height)
            (current-count (default-to u0 (map-get? product-supplier-count product-id)))
        )
        (asserts! (get is-verified supplier) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active product) ERR-INVALID-STATUS)
        (asserts! (<= quality-rating u10) ERR-INVALID-STATUS)
        (map-set supplier-attestations { product-id: product-id, supplier: tx-sender } {
            attestation: attestation,
            timestamp: current-block,
            quality-rating: quality-rating
        })
        (map-set product-suppliers { product-id: product-id, supplier-index: current-count } tx-sender)
        (map-set product-supplier-count product-id (+ current-count u1))
        (ok true)
    )
)

(define-public (assign-to-restaurant (product-id uint) (restaurant principal))
    (let
        (
            (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        )
        (asserts! (is-eq (get current-holder product) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get current-status product) STATUS-DELIVERED) ERR-INVALID-STATUS)
        (map-set products product-id (merge product { restaurant: (some restaurant) }))
        (ok true)
    )
)

(define-public (deactivate-product (product-id uint))
    (let
        (
            (product (unwrap! (map-get? products product-id) ERR-PRODUCT-NOT-FOUND))
        )
        (asserts! (or (is-eq (get current-holder product) tx-sender) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
        (map-set products product-id (merge product { is-active: false }))
        (ok true)
    )
)

(define-read-only (get-product (product-id uint))
    (ok (map-get? products product-id))
)

(define-read-only (get-product-journey (product-id uint) (stage uint))
    (ok (map-get? product-journey { product-id: product-id, stage: stage }))
)

(define-read-only (get-supplier (supplier principal))
    (ok (map-get? suppliers supplier))
)

(define-read-only (get-supplier-attestation (product-id uint) (supplier principal))
    (ok (map-get? supplier-attestations { product-id: product-id, supplier: supplier }))
)

(define-read-only (get-product-supplier (product-id uint) (supplier-index uint))
    (ok (map-get? product-suppliers { product-id: product-id, supplier-index: supplier-index }))
)

(define-read-only (get-product-supplier-count (product-id uint))
    (ok (default-to u0 (map-get? product-supplier-count product-id)))
)

(define-read-only (get-current-product-id)
    (ok (var-get product-id-nonce))
)

(define-read-only (get-product-freshness (product-id uint))
    (match (map-get? products product-id)
        product (ok {
            product-id: product-id,
            harvest-date: (get harvest-date product),
            current-block: stacks-block-height,
            blocks-elapsed: (- stacks-block-height (get harvest-date product)),
            status: (get current-status product),
            is-active: (get is-active product)
        })
        ERR-PRODUCT-NOT-FOUND
    )
)
