
;; title: apprentice-manager
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

;; Apprentice Management Contract
;; Handles apprentice registration, progress tracking, and certification

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-APPRENTICE-NOT-FOUND (err u101))
(define-constant ERR-APPRENTICE-EXISTS (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INVALID-PROGRESS (err u104))
(define-constant ERR-PROGRAM-NOT-FOUND (err u105))
(define-constant ERR-MILESTONE-NOT-FOUND (err u106))

;; Data Variables
(define-data-var next-apprentice-id uint u1)
(define-data-var next-program-id uint u1)
(define-data-var next-milestone-id uint u1)

;; Data Maps
(define-map apprentices
  { apprentice-id: uint }
  {
    principal: principal,
    name: (string-ascii 100),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    date-of-birth: uint,
    education-level: (string-ascii 50),
    status: (string-ascii 20),
    registration-date: uint,
    program-id: (optional uint),
    completion-date: (optional uint)
  }
)

(define-map apprentice-by-principal
  { principal: principal }
  { apprentice-id: uint }
)

(define-map training-programs
  { program-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    duration-weeks: uint,
    industry-sector: (string-ascii 50),
    skill-level: (string-ascii 20),
    created-by: principal,
    created-date: uint,
    active: bool
  }
)

(define-map apprentice-progress
  { apprentice-id: uint, milestone-id: uint }
  {
    completed: bool,
    completion-date: (optional uint),
    score: (optional uint),
    notes: (optional (string-ascii 500))
  }
)

(define-map program-milestones
  { program-id: uint, milestone-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    order-index: uint,
    required: bool,
    skill-category: (string-ascii 50)
  }
)

(define-map apprentice-certifications
  { apprentice-id: uint, certification-id: uint }
  {
    name: (string-ascii 100),
    issuer: principal,
    issue-date: uint,
    expiry-date: (optional uint),
    verification-hash: (string-ascii 64)
  }
)

;; Read-only functions

(define-read-only (get-apprentice (apprentice-id uint))
  (map-get? apprentices { apprentice-id: apprentice-id })
)

(define-read-only (get-apprentice-by-principal (user principal))
  (match (map-get? apprentice-by-principal { principal: user })
    apprentice-data (get-apprentice (get apprentice-id apprentice-data))
    none
  )
)

(define-read-only (get-training-program (program-id uint))
  (map-get? training-programs { program-id: program-id })
)

(define-read-only (get-apprentice-progress (apprentice-id uint) (milestone-id uint))
  (map-get? apprentice-progress { apprentice-id: apprentice-id, milestone-id: milestone-id })
)

(define-read-only (get-program-milestone (program-id uint) (milestone-id uint))
  (map-get? program-milestones { program-id: program-id, milestone-id: milestone-id })
)

(define-read-only (get-apprentice-certification (apprentice-id uint) (certification-id uint))
  (map-get? apprentice-certifications { apprentice-id: apprentice-id, certification-id: certification-id })
)

(define-read-only (calculate-program-completion (apprentice-id uint) (program-id uint))
  (let
    (
      (total-milestones u0)
      (completed-milestones u0)
    )
    ;; This would require iteration in a real implementation
    ;; For now, return a placeholder percentage
    u0
  )
)

;; Public functions

(define-public (register-apprentice
  (name (string-ascii 100))
  (email (string-ascii 100))
  (phone (string-ascii 20))
  (date-of-birth uint)
  (education-level (string-ascii 50))
)
  (let
    (
      (apprentice-id (var-get next-apprentice-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-none (map-get? apprentice-by-principal { principal: tx-sender })) ERR-APPRENTICE-EXISTS)

    (map-set apprentices
      { apprentice-id: apprentice-id }
      {
        principal: tx-sender,
        name: name,
        email: email,
        phone: phone,
        date-of-birth: date-of-birth,
        education-level: education-level,
        status: "registered",
        registration-date: current-time,
        program-id: none,
        completion-date: none
      }
    )

    (map-set apprentice-by-principal
      { principal: tx-sender }
      { apprentice-id: apprentice-id }
    )

    (var-set next-apprentice-id (+ apprentice-id u1))
    (ok apprentice-id)
  )
)

(define-public (create-training-program
  (name (string-ascii 100))
  (description (string-ascii 500))
  (duration-weeks uint)
  (industry-sector (string-ascii 50))
  (skill-level (string-ascii 20))
)
  (let
    (
      (program-id (var-get next-program-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (map-set training-programs
      { program-id: program-id }
      {
        name: name,
        description: description,
        duration-weeks: duration-weeks,
        industry-sector: industry-sector,
        skill-level: skill-level,
        created-by: tx-sender,
        created-date: current-time,
        active: true
      }
    )

    (var-set next-program-id (+ program-id u1))
    (ok program-id)
  )
)

(define-public (enroll-in-program (apprentice-id uint) (program-id uint))
  (let
    (
      (apprentice-data (unwrap! (get-apprentice apprentice-id) ERR-APPRENTICE-NOT-FOUND))
      (program-data (unwrap! (get-training-program program-id) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq (get principal apprentice-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get active program-data) ERR-INVALID-STATUS)

    (map-set apprentices
      { apprentice-id: apprentice-id }
      (merge apprentice-data {
        program-id: (some program-id),
        status: "enrolled"
      })
    )

    (ok true)
  )
)

(define-public (add-program-milestone
  (program-id uint)
  (name (string-ascii 100))
  (description (string-ascii 500))
  (order-index uint)
  (required bool)
  (skill-category (string-ascii 50))
)
  (let
    (
      (milestone-id (var-get next-milestone-id))
      (program-data (unwrap! (get-training-program program-id) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq (get created-by program-data) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set program-milestones
      { program-id: program-id, milestone-id: milestone-id }
      {
        name: name,
        description: description,
        order-index: order-index,
        required: required,
        skill-category: skill-category
      }
    )

    (var-set next-milestone-id (+ milestone-id u1))
    (ok milestone-id)
  )
)

(define-public (complete-milestone
  (apprentice-id uint)
  (milestone-id uint)
  (score uint)
  (notes (string-ascii 500))
)
  (let
    (
      (apprentice-data (unwrap! (get-apprentice apprentice-id) ERR-APPRENTICE-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get principal apprentice-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= score u100) ERR-INVALID-PROGRESS)

    (map-set apprentice-progress
      { apprentice-id: apprentice-id, milestone-id: milestone-id }
      {
        completed: true,
        completion-date: (some current-time),
        score: (some score),
        notes: (some notes)
      }
    )

    (ok true)
  )
)

(define-public (issue-certification
  (apprentice-id uint)
  (certification-id uint)
  (name (string-ascii 100))
  (expiry-date (optional uint))
  (verification-hash (string-ascii 64))
)
  (let
    (
      (apprentice-data (unwrap! (get-apprentice apprentice-id) ERR-APPRENTICE-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    ;; Only authorized issuers can issue certifications
    ;; In a real implementation, this would check against a list of authorized issuers

    (map-set apprentice-certifications
      { apprentice-id: apprentice-id, certification-id: certification-id }
      {
        name: name,
        issuer: tx-sender,
        issue-date: current-time,
        expiry-date: expiry-date,
        verification-hash: verification-hash
      }
    )

    (ok true)
  )
)

(define-public (update-apprentice-status (apprentice-id uint) (new-status (string-ascii 20)))
  (let
    (
      (apprentice-data (unwrap! (get-apprentice apprentice-id) ERR-APPRENTICE-NOT-FOUND))
    )
    (asserts! (is-eq (get principal apprentice-data) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set apprentices
      { apprentice-id: apprentice-id }
      (merge apprentice-data { status: new-status })
    )

    (ok true)
  )
)

(define-public (complete-program (apprentice-id uint))
  (let
    (
      (apprentice-data (unwrap! (get-apprentice apprentice-id) ERR-APPRENTICE-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get principal apprentice-data) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set apprentices
      { apprentice-id: apprentice-id }
      (merge apprentice-data {
        status: "completed",
        completion-date: (some current-time)
      })
    )

    (ok true)
  )
)
