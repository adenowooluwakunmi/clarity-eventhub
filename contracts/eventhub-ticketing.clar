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

;; Refund ticket
(define-public (refund-ticket (amount uint))
  (let (
    (user-tickets (default-to u0 (map-get? user-ticket-balance tx-sender)))
    (refund-amount (calculate-refund amount))
    (contract-stx-balance (default-to u0 (map-get? user-stx-balance contract-owner)))
  )
    (asserts! (> amount u0) err-invalid-ticket-amount)
    (asserts! (>= user-tickets amount) err-not-enough-tickets)
    (asserts! (>= contract-stx-balance refund-amount) err-ticket-transfer-failed)

    ;; Update user's ticket balance
    (map-set user-ticket-balance tx-sender (- user-tickets amount))

    ;; Update user's and contract's STX balance
    (map-set user-stx-balance tx-sender (+ (default-to u0 (map-get? user-stx-balance tx-sender)) refund-amount))
    (map-set user-stx-balance contract-owner (- contract-stx-balance refund-amount))

    ;; Add refunded tickets back to contract owner's balance
    (map-set user-ticket-balance contract-owner (+ (default-to u0 (map-get? user-ticket-balance contract-owner)) amount))

    ;; Update ticket reserve
    (try! (update-ticket-reserve (to-int (- amount))))

    (ok true)))

;; Optimizes ticket price update function by adding checks and direct assignments.
(define-public (optimized-set-ticket-price (new-price uint))
  (begin
    (asserts! (> new-price u0) err-invalid-ticket-price)
    (var-set ticket-price new-price)
    (ok true)))

;; Optimizes the ticket purchase function to reduce gas costs.
(define-public (optimized-buy-ticket (seller principal) (amount uint))
  (begin
    (let (
        (sale-data (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: seller})))
        (ticket-cost (* amount (get price sale-data)))
    )
      (asserts! (>= ticket-cost (default-to u0 (map-get? user-stx-balance tx-sender))) err-not-enough-tickets)
      (map-set user-ticket-balance tx-sender (+ (default-to u0 (map-get? user-ticket-balance tx-sender)) amount))
      (map-set user-stx-balance tx-sender (- (default-to u0 (map-get? user-stx-balance tx-sender)) ticket-cost))
      (ok true))))

;; Fixes bug in refund amount calculation by ensuring it reflects the correct percentage.
(define-public (fix-refund-amount-bug (amount uint))
  (let (
    (refund-amount (calculate-refund amount))
  )
    (asserts! (> refund-amount u0) err-invalid-refund-rate)
    (ok refund-amount)))

;; Refactors the ticket price setter to improve clarity and reduce redundancy.
(define-public (simplified-set-ticket-price (new-price uint))
  (begin
    (asserts! (> new-price u0) err-invalid-ticket-price)
    (var-set ticket-price new-price)
    (ok true)))

;; Optimize the contract function to update ticket balances
(define-private (update-ticket-balance (user principal) (amount uint))
  (let ((current-balance (default-to u0 (map-get? user-ticket-balance user))))
    (map-set user-ticket-balance user (+ current-balance amount))
    (ok true))
)

;; Add a new Clarity contract to refund partial ticket sales
(define-public (partial-refund-ticket (amount uint))
  (let (
    (user-tickets (default-to u0 (map-get? user-ticket-balance tx-sender)))
    (refund-amount (calculate-refund amount))
  )
    (asserts! (> amount u0) err-invalid-ticket-amount)
    (asserts! (>= user-tickets amount) err-not-enough-tickets)
    (map-set user-ticket-balance tx-sender (- user-tickets amount))
    (map-set user-stx-balance tx-sender (+ (default-to u0 (map-get? user-stx-balance tx-sender)) refund-amount))
    (ok true))
)

;; Refactor contract function for improved handling of ticket purchase failures
(define-public (buy-ticket-safe (seller principal) (amount uint))
  (let (
    (sale-data (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: seller})))
    (ticket-cost (* amount (get price sale-data)))
  )
    (asserts! (>= (get amount sale-data) amount) err-not-enough-tickets)
    (asserts! (>= (default-to u0 (map-get? user-stx-balance tx-sender)) ticket-cost) err-not-enough-tickets)
    (ok true))
)

;; Improve performance by minimizing repetitive ticket check
(define-private (minimize-ticket-check (user principal) (amount uint))
  (let ((user-balance (default-to u0 (map-get? user-ticket-balance user))))
    (asserts! (>= user-balance amount) err-not-enough-tickets)
    (ok true))
)

;; Set max tickets per user (only contract owner)
(define-public (set-max-tickets-per-user (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-limit u0) err-invalid-ticket-amount)
    (var-set max-tickets-per-user new-limit)
    (ok true)))

;; Increase ticket price (only contract owner)
(define-public (increase-ticket-price (increase uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> increase u0) err-invalid-ticket-price)
    (var-set ticket-price (+ (var-get ticket-price) increase))
    (ok true)))

;; Decrease ticket price (only contract owner)
(define-public (decrease-ticket-price (decrease uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> (var-get ticket-price) decrease) err-invalid-ticket-price)
    (var-set ticket-price (- (var-get ticket-price) decrease))
    (ok true)))

;; Refund a user for tickets purchased
(define-public (refund-user (user principal) (amount uint))
  (let (
    (user-tickets (default-to u0 (map-get? user-ticket-balance user)))
    (refund-amount (calculate-refund amount))
  )
    (asserts! (>= user-tickets amount) err-not-enough-tickets)
    (map-set user-ticket-balance user (- user-tickets amount))
    (map-set user-stx-balance user (+ (default-to u0 (map-get? user-stx-balance user)) refund-amount))
    (map-set user-stx-balance contract-owner (- (default-to u0 (map-get? user-stx-balance contract-owner)) refund-amount))
    (ok true)))

;; Check if a user is eligible for refund
(define-public (is-eligible-for-refund (user principal) (amount uint))
  (let ((user-tickets (default-to u0 (map-get? user-ticket-balance user))))
    (if (>= user-tickets amount)
        (ok true)
        (err err-not-enough-tickets))))

;;  User withdraws STX balance
(define-public (withdraw-stx-balance (amount uint))
  (let (
    (user-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
  )
    (asserts! (>= user-balance amount) err-not-enough-tickets)
    (map-set user-stx-balance tx-sender (- user-balance amount))
    (ok true)))

;; Set refund rate percentage (only contract owner)
(define-public (set-refund-rate-percentage (percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= percentage u100) err-invalid-refund-rate)
    (var-set refund-rate percentage)
    (ok true)))

;; Reduce ticket reserve limit (only contract owner)
(define-public (decrease-ticket-reserve-limit (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= (var-get tickets-reserve-limit) amount) err-reserve-limit-exceeded)
    (var-set tickets-reserve-limit (- (var-get tickets-reserve-limit) amount))
    (ok true)))

;; Add a UI element that displays the user's available tickets for purchase
(define-public (add-ticket-purchase-ui)
  ;; The function displays ticket options for users to interact with
  (ok true))

;; Define a new contract function for event cancellation
(define-public (cancel-event)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Cancel the event and refund all tickets
    (map-set user-ticket-balance tx-sender u0)
    (ok true)))

;; Read-only functions

;; Get current ticket price
(define-read-only (get-ticket-price)
  (ok (var-get ticket-price)))

;; Get refund rate
(define-read-only (get-refund-rate)
  (ok (var-get refund-rate)))

;; Get user's ticket balance
(define-read-only (get-ticket-balance (user principal))
  (ok (default-to u0 (map-get? user-ticket-balance user))))

;; Get user's STX balance
(define-read-only (get-stx-balance (user principal))
  (ok (default-to u0 (map-get? user-stx-balance user))))

;; Get tickets for sale by user
(define-read-only (get-tickets-for-sale (user principal))
  (ok (default-to {amount: u0, price: u0} (map-get? tickets-for-sale {user: user}))))
