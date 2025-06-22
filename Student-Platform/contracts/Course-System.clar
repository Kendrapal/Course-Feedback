;; ACADEMIC COURSE FEEDBACK REGISTRY - BLOCKCHAIN-BASED STUDENT EVALUATION PLATFORM SMART CONTRACT
;;
;; A comprehensive smart contract system for managing academic course evaluations
;; in a decentralized environment. This platform enables students to submit anonymous
;; feedback and ratings for courses they're enrolled in, while providing instructors
;; and administrators with transparent tools to manage course offerings and analyze
;; student satisfaction metrics. The system ensures data integrity, prevents duplicate
;; submissions, and maintains proper access controls throughout the evaluation process.

;; SYSTEM CONFIGURATION CONSTANTS

;; Contract administrator (deployer address)
(define-constant contract-administrator tx-sender)

;; Rating scale boundaries
(define-constant minimum-rating-value u1)
(define-constant maximum-rating-value u5)

;; ERROR CODE DEFINITIONS

(define-constant ERR-ADMIN-PRIVILEGES-REQUIRED (err u100))
(define-constant ERR-COURSE-DOES-NOT-EXIST (err u101))
(define-constant ERR-COURSE-IDENTIFIER-CONFLICT (err u102))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u103))
(define-constant ERR-RATING-OUT-OF-BOUNDS (err u104))
(define-constant ERR-EVALUATION-ALREADY-SUBMITTED (err u105))
(define-constant ERR-STUDENT-NOT-REGISTERED (err u106))
(define-constant ERR-COURSE-NOT-ACCEPTING-EVALUATIONS (err u107))
(define-constant ERR-INVALID-DATA-FORMAT (err u108))

;; CORE DATA STORAGE MAPS

;; Primary course information repository
;; Stores comprehensive course metadata and instructor assignments
(define-map academic-course-catalog
  { course-unique-id: uint }
  {
    course-display-name: (string-ascii 100),
    assigned-instructor: principal,
    accepts-new-evaluations: bool
  }
)

;; Student feedback and rating storage
;; Contains individual student evaluations linked to specific courses
(define-map student-feedback-database
  { course-unique-id: uint, evaluating-student: principal }
  {
    numerical-rating: uint,
    written-commentary: (string-utf8 500),
    evaluation-timestamp: uint
  }
)

;; Course enrollment tracking system
;; Maintains records of which students are authorized to evaluate each course
(define-map course-enrollment-records
  { course-unique-id: uint, enrolled-student: principal }
  { is-currently-enrolled: bool }
)

;; Aggregated rating statistics
;; Enables efficient calculation of course rating averages and totals
(define-map course-rating-aggregates
  { course-unique-id: uint }
  {
    cumulative-rating-sum: uint,
    total-evaluation-count: uint
  }
)

;; Global course identifier counter
(define-data-var course-id-counter uint u0)

;; AUTHORIZATION AND ACCESS CONTROL

;; Determines if current transaction sender has administrative privileges
(define-read-only (has-admin-privileges)
  (is-eq tx-sender contract-administrator)
)

;; Checks if current sender is the designated instructor for a specific course
(define-read-only (is-designated-course-instructor (course-unique-id uint))
  (match (retrieve-course-information course-unique-id)
    course-details (is-eq tx-sender (get assigned-instructor course-details))
    false
  )
)

;; Validates if caller has management rights over a course (admin or instructor)
(define-read-only (can-modify-course (course-unique-id uint))
  (or 
    (has-admin-privileges)
    (is-designated-course-instructor course-unique-id)
  )
)

;; INPUT VALIDATION UTILITIES

;; Ensures course names meet minimum requirements and length constraints
(define-read-only (is-course-name-valid (course-name (string-ascii 100)))
  (> (len course-name) u0)
)

;; Validates student feedback text meets content and length requirements
(define-read-only (is-feedback-text-valid (feedback-content (string-utf8 500)))
  (let ((content-length (len feedback-content)))
    (and (>= content-length u1) (<= content-length u500))
  )
)

;; COURSE INFORMATION RETRIEVAL FUNCTIONS

;; Fetches complete course details by identifier
(define-read-only (retrieve-course-information (course-unique-id uint))
  (map-get? academic-course-catalog { course-unique-id: course-unique-id })
)

;; Verifies student enrollment status for a specific course
(define-read-only (verify-student-enrollment-status (course-unique-id uint) (student-address principal))
  (default-to 
    false
    (get is-currently-enrolled 
         (map-get? course-enrollment-records 
                   { course-unique-id: course-unique-id, 
                     enrolled-student: student-address }))
  )
)

;; Retrieves existing student evaluation for a course
(define-read-only (fetch-student-course-evaluation (course-unique-id uint) (student-address principal))
  (map-get? student-feedback-database 
    { course-unique-id: course-unique-id, 
      evaluating-student: student-address })
)

;; Computes average rating score for a course
(define-read-only (compute-course-average-rating (course-unique-id uint))
  (match (map-get? course-rating-aggregates { course-unique-id: course-unique-id })
    aggregate-data 
      (let (
        (total-points (get cumulative-rating-sum aggregate-data))
        (evaluation-count (get total-evaluation-count aggregate-data))
      )
        (if (> evaluation-count u0)
          (/ total-points evaluation-count)
          u0
        )
      )
    u0
  )
)

;; Returns total number of evaluations submitted for a course
(define-read-only (get-total-evaluation-count (course-unique-id uint))
  (default-to
    u0
    (get total-evaluation-count 
         (map-get? course-rating-aggregates { course-unique-id: course-unique-id }))
  )
)

;; COURSE ADMINISTRATION FUNCTIONS

;; Creates a new course entry in the academic catalog
(define-public (establish-new-academic-course (course-display-name (string-ascii 100)))
  (let ((new-course-id (+ (var-get course-id-counter) u1)))
    
    ;; Administrative privileges required for course creation
    (asserts! (has-admin-privileges) ERR-ADMIN-PRIVILEGES-REQUIRED)
    
    ;; Validate course name meets requirements
    (asserts! (is-course-name-valid course-display-name) ERR-INVALID-DATA-FORMAT)
    
    ;; Register new course in catalog
    (map-set academic-course-catalog
      { course-unique-id: new-course-id }
      {
        course-display-name: course-display-name,
        assigned-instructor: tx-sender,
        accepts-new-evaluations: true
      }
    )
    
    ;; Initialize rating aggregation tracking
    (map-set course-rating-aggregates
      { course-unique-id: new-course-id }
      {
        cumulative-rating-sum: u0,
        total-evaluation-count: u0
      }
    )
    
    ;; Update global course counter
    (var-set course-id-counter new-course-id)
    
    ;; Return new course identifier
    (ok new-course-id)
  )
)

;; Updates instructor assignment for an existing course
(define-public (reassign-course-instructor (course-unique-id uint) (new-instructor-address principal))
  (match (retrieve-course-information course-unique-id)
    existing-course-data
      (begin
        ;; Only administrators can reassign instructors
        (asserts! (has-admin-privileges) ERR-ADMIN-PRIVILEGES-REQUIRED)
        
        ;; Update instructor assignment
        (map-set academic-course-catalog
          { course-unique-id: course-unique-id }
          (merge existing-course-data 
                 { assigned-instructor: new-instructor-address })
        )
        
        (ok true)
      )
    ERR-COURSE-DOES-NOT-EXIST
  )
)

;; STUDENT ENROLLMENT MANAGEMENT

;; Enrolls a student in a course for evaluation eligibility
(define-public (enroll-student-in-course (course-unique-id uint) (target-student-address principal))
  (let (
    (target-enrollment-address (if (is-eq target-student-address tx-sender) 
                                   tx-sender 
                                   target-student-address))
  )
    ;; Verify course exists
    (asserts! (is-some (retrieve-course-information course-unique-id)) ERR-COURSE-DOES-NOT-EXIST)
    
    ;; Verify caller has course management permissions
    (asserts! (can-modify-course course-unique-id) ERR-INSUFFICIENT-PERMISSIONS)
    
    ;; Register student enrollment
    (map-set course-enrollment-records
      { course-unique-id: course-unique-id, 
        enrolled-student: target-enrollment-address }
      { is-currently-enrolled: true }
    )
    
    (ok true)
  )
)

;; EVALUATION SUBMISSION SYSTEM

;; Processes and records student course evaluation
(define-public (submit-student-course-evaluation 
                (course-unique-id uint) 
                (numerical-rating uint) 
                (written-commentary (string-utf8 500)))
  (let (
    (course-information (retrieve-course-information course-unique-id))
    (existing-evaluation (fetch-student-course-evaluation course-unique-id tx-sender))
    (current-aggregates (map-get? course-rating-aggregates { course-unique-id: course-unique-id }))
  )
    ;; Verify course exists in catalog
    (asserts! (is-some course-information) ERR-COURSE-DOES-NOT-EXIST)
    
    ;; Verify course accepts new evaluations
    (asserts! (get accepts-new-evaluations (unwrap-panic course-information)) 
             ERR-COURSE-NOT-ACCEPTING-EVALUATIONS)
    
    ;; Verify student enrollment eligibility
    (asserts! (verify-student-enrollment-status course-unique-id tx-sender) 
             ERR-STUDENT-NOT-REGISTERED)
    
    ;; Validate rating within acceptable range
    (asserts! (and (>= numerical-rating minimum-rating-value) 
                  (<= numerical-rating maximum-rating-value)) 
             ERR-RATING-OUT-OF-BOUNDS)
    
    ;; Prevent duplicate evaluation submissions
    (asserts! (is-none existing-evaluation) ERR-EVALUATION-ALREADY-SUBMITTED)
    
    ;; Validate written feedback format
    (asserts! (is-feedback-text-valid written-commentary) ERR-INVALID-DATA-FORMAT)
    
    ;; Store student evaluation
    (map-set student-feedback-database
      { course-unique-id: course-unique-id, 
        evaluating-student: tx-sender }
      {
        numerical-rating: numerical-rating,
        written-commentary: written-commentary,
        evaluation-timestamp: block-height
      }
    )
    
    ;; Update course rating aggregates
    (match current-aggregates
      existing-aggregates
        (map-set course-rating-aggregates
          { course-unique-id: course-unique-id }
          {
            cumulative-rating-sum: (+ (get cumulative-rating-sum existing-aggregates) numerical-rating),
            total-evaluation-count: (+ (get total-evaluation-count existing-aggregates) u1)
          }
        )
      ;; Initialize aggregates if none exist
      (map-set course-rating-aggregates
        { course-unique-id: course-unique-id }
        {
          cumulative-rating-sum: numerical-rating,
          total-evaluation-count: u1
        }
      )
    )
    
    (ok true)
  )
)

;; COURSE STATUS MANAGEMENT

;; Controls whether a course accepts new evaluations
(define-public (modify-course-evaluation-status (course-unique-id uint) (evaluation-acceptance-status bool))
  (match (retrieve-course-information course-unique-id)
    course-data
      (begin
        ;; Verify caller has course management permissions
        (asserts! (can-modify-course course-unique-id) ERR-INSUFFICIENT-PERMISSIONS)
        
        ;; Update course evaluation acceptance status
        (map-set academic-course-catalog
          { course-unique-id: course-unique-id }
          (merge course-data 
                 { accepts-new-evaluations: evaluation-acceptance-status })
        )
        
        (ok true)
      )
    ERR-COURSE-DOES-NOT-EXIST
  )
)