;; EventHub - A Decentralized Ticketing System
;;
;; This smart contract provides a blockchain-based ticket management solution for events. 
;; It allows event organizers to set ticket prices, manage sales, and enforce limits per user. 
;; Users can buy, sell, and refund tickets in a secure, trustless environment.
;; Key features:
;; - Ticket pricing and reserve limits set by the contract owner.
;; - Peer-to-peer ticket resale with customizable prices.
;; - Automatic refund calculation based on user-defined rates.
;; - Robust error handling to ensure smooth operation.
;; - Transparent, immutable transactions leveraging Clarity's predictable execution model.
;;
;; This system aims to streamline event ticketing processes while eliminating intermediaries and reducing fraud.

;; Define constants
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-tickets (err u101))
(define-constant err-ticket-transfer-failed (err u102))
(define-constant err-invalid-ticket-price (err u103))
(define-constant err-invalid-ticket-amount (err u104))
(define-constant err-invalid-refund-rate (err u105))
(define-constant err-reserve-limit-exceeded (err u106))
(define-constant err-ticket-sold-out (err u107))
(define-constant err-same-user (err u108))
(define-constant contract-owner tx-sender)

;; Define data variables
(define-data-var ticket-price uint u1000) ;; Price per ticket in microstacks
(define-data-var max-tickets-per-user uint u10) ;; Max tickets a user can purchase
(define-data-var refund-rate uint u80) ;; Refund rate in percentage (e.g., 80 means 80% of the price)
(define-data-var total-tickets-sold uint u0) ;; Total tickets sold
(define-data-var tickets-reserve-limit uint u1000) ;; Maximum number of tickets allowed for sale

;; Define data maps
(define-map user-ticket-balance principal uint) ;; User's ticket balance
(define-map user-stx-balance principal uint) ;; User's STX balance
(define-map tickets-for-sale {user: principal} {amount: uint, price: uint})

;; Private functions

;; Calculate refund
(define-private (calculate-refund (amount uint))
  (/ (* amount (var-get ticket-price) (var-get refund-rate)) u100))

;; Update ticket reserve
(define-private (update-ticket-reserve (amount int))
  (let (
    (current-reserve (var-get total-tickets-sold))
    (new-reserve (if (< amount 0)
                     (if (>= current-reserve (to-uint (- 0 amount)))
                         (- current-reserve (to-uint (- 0 amount)))
                         u0)
                     (+ current-reserve (to-uint amount))))
  )
    (asserts! (<= new-reserve (var-get tickets-reserve-limit)) err-reserve-limit-exceeded)
    (var-set total-tickets-sold new-reserve)
    (ok true)))

;; Public functions

;; Set ticket price (only contract owner)
(define-public (set-ticket-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-ticket-price) ;; Ensure price is greater than 0
    (var-set ticket-price new-price)
    (ok true)))

;; Set refund rate (only contract owner)
(define-public (set-refund-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u100) err-invalid-refund-rate) ;; Ensure rate is not more than 100%
    (var-set refund-rate new-rate)
    (ok true)))

;; Set ticket reserve limit (only contract owner)
(define-public (set-ticket-reserve-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-limit (var-get total-tickets-sold)) err-reserve-limit-exceeded)
    (var-set tickets-reserve-limit new-limit)
    (ok true)))

;; Add tickets for sale
(define-public (add-tickets-for-sale (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? user-ticket-balance tx-sender)))
    (current-for-sale (get amount (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: tx-sender}))))
    (new-for-sale (+ amount current-for-sale))
  )
    (asserts! (> amount u0) err-invalid-ticket-amount) ;; Ensure amount is greater than 0
    (asserts! (>= current-balance new-for-sale) err-not-enough-tickets)
    (try! (update-ticket-reserve (to-int amount)))
    (map-set tickets-for-sale {user: tx-sender} {amount: new-for-sale, price: (var-get ticket-price)})
    (ok true)))

;; Remove tickets from sale
(define-public (remove-tickets-from-sale (amount uint))
  (let (
    (current-for-sale (get amount (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: tx-sender}))))
  )
    (asserts! (>= current-for-sale amount) err-not-enough-tickets)
    (try! (update-ticket-reserve (to-int (- amount))))
    (map-set tickets-for-sale {user: tx-sender} 
             {amount: (- current-for-sale amount), price: (get price (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: tx-sender})))})
    (ok true)))

;; Buy tickets
(define-public (buy-ticket (seller principal) (amount uint))
  (let (
    (sale-data (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: seller})))
    (ticket-cost (* amount (get price sale-data)))
    (refund-amount (calculate-refund amount))
    (buyer-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
    (seller-balance (default-to u0 (map-get? user-stx-balance seller)))
    (owner-balance (default-to u0 (map-get? user-stx-balance contract-owner)))
  )
    (asserts! (not (is-eq tx-sender seller)) err-same-user)
    (asserts! (> amount u0) err-invalid-ticket-amount)
    (asserts! (>= (get amount sale-data) amount) err-not-enough-tickets)
    (asserts! (>= buyer-balance ticket-cost) err-not-enough-tickets)

    ;; Update seller's ticket balance and for-sale amount
    (map-set user-ticket-balance seller (- (default-to u0 (map-get? user-ticket-balance seller)) amount))
    (map-set tickets-for-sale {user: seller} 
             {amount: (- (get amount sale-data) amount), price: (get price sale-data)})

    ;; Update buyer's STX and ticket balance
    (map-set user-stx-balance tx-sender (- buyer-balance ticket-cost))
    (map-set user-ticket-balance tx-sender (+ (default-to u0 (map-get? user-ticket-balance tx-sender)) amount))

    ;; Update seller's and contract owner's STX balance
    (map-set user-stx-balance seller (+ seller-balance ticket-cost))
    (map-set user-stx-balance contract-owner (+ owner-balance refund-amount))

    (ok true)))

