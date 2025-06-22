# Academic Course Feedback Registry Smart Contract

A comprehensive blockchain-based platform for managing academic course evaluations in a decentralized environment. This smart contract enables students to submit anonymous feedback and ratings for courses while providing instructors and administrators with transparent tools to manage course offerings and analyze student satisfaction metrics.

## Features

- **Decentralized Course Management**: Create and manage academic courses on the blockchain
- **Anonymous Student Evaluations**: Students can submit ratings and written feedback anonymously
- **Access Control**: Multi-level permissions for administrators, instructors, and students
- **Data Integrity**: Prevents duplicate submissions and ensures rating consistency
- **Real-time Analytics**: Automatic calculation of course averages and evaluation counts
- **Enrollment Management**: Track student eligibility for course evaluations

## Contract Overview

### Core Components

1. **Course Catalog**: Stores course information and instructor assignments
2. **Student Feedback Database**: Contains individual evaluations with ratings and comments
3. **Enrollment Records**: Tracks which students can evaluate specific courses
4. **Rating Aggregates**: Maintains cumulative statistics for efficient analytics

### Rating System

- Rating scale: 1-5 (1 = Poor, 5 = Excellent)
- Written feedback: Up to 500 characters
- One evaluation per student per course

## Getting Started

### Prerequisites

- Stacks blockchain environment
- Clarity smart contract deployment tools
- STX tokens for transaction fees

### Deployment

1. Deploy the smart contract to the Stacks blockchain
2. The deployer automatically becomes the contract administrator
3. Begin creating courses and enrolling students

## Core Functions

### Administrative Functions

#### `establish-new-academic-course`
Creates a new course in the academic catalog.

**Parameters:**
- `course-display-name`: Course name (max 100 ASCII characters)

**Returns:** New course ID

**Access:** Admin only

```clarity
(establish-new-academic-course "Introduction to Blockchain")
```

#### `reassign-course-instructor`
Updates the instructor assigned to a course.

**Parameters:**
- `course-unique-id`: Course identifier
- `new-instructor-address`: Principal address of new instructor

**Access:** Admin only

### Course Management Functions

#### `enroll-student-in-course`
Enrolls a student in a course, making them eligible to submit evaluations.

**Parameters:**
- `course-unique-id`: Course identifier
- `target-student-address`: Student's principal address

**Access:** Admin or course instructor

#### `modify-course-evaluation-status`
Controls whether a course accepts new evaluations.

**Parameters:**
- `course-unique-id`: Course identifier
- `evaluation-acceptance-status`: Boolean (true = accepting, false = closed)

**Access:** Admin or course instructor

### Student Functions

#### `submit-student-course-evaluation`
Submits a course evaluation with rating and written feedback.

**Parameters:**
- `course-unique-id`: Course identifier
- `numerical-rating`: Rating from 1-5
- `written-commentary`: Feedback text (max 500 UTF-8 characters)

**Access:** Enrolled students only (one submission per course)

```clarity
(submit-student-course-evaluation u1 u5 "Excellent course! Very informative and well-structured.")
```

## Read-Only Functions

### Course Information

#### `retrieve-course-information`
Gets complete course details including name, instructor, and evaluation status.

#### `compute-course-average-rating`
Calculates the average rating for a course.

#### `get-total-evaluation-count`
Returns the total number of evaluations submitted for a course.

### Student & Enrollment

#### `verify-student-enrollment-status`
Checks if a student is enrolled in a specific course.

#### `fetch-student-course-evaluation`
Retrieves a student's evaluation for a course (if exists).

### Access Control

#### `has-admin-privileges`
Checks if the caller has administrative privileges.

#### `is-designated-course-instructor`
Verifies if the caller is the instructor for a specific course.

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR-ADMIN-PRIVILEGES-REQUIRED | Administrative access required |
| 101 | ERR-COURSE-DOES-NOT-EXIST | Course ID not found |
| 102 | ERR-COURSE-IDENTIFIER-CONFLICT | Course ID already exists |
| 103 | ERR-INSUFFICIENT-PERMISSIONS | Caller lacks required permissions |
| 104 | ERR-RATING-OUT-OF-BOUNDS | Rating must be between 1-5 |
| 105 | ERR-EVALUATION-ALREADY-SUBMITTED | Student already evaluated this course |
| 106 | ERR-STUDENT-NOT-REGISTERED | Student not enrolled in course |
| 107 | ERR-COURSE-NOT-ACCEPTING-EVALUATIONS | Course closed for evaluations |
| 108 | ERR-INVALID-DATA-FORMAT | Invalid input data format |

## Usage Examples

### Setting Up a Course

```clarity
;; 1. Create a new course (admin)
(establish-new-academic-course "Advanced Smart Contracts")

;; 2. Enroll students (admin or instructor)
(enroll-student-in-course u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(enroll-student-in-course u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; 3. Students submit evaluations
(submit-student-course-evaluation u1 u4 "Great course content and presentation!")
```

### Analyzing Course Performance

```clarity
;; Get course average rating
(compute-course-average-rating u1)

;; Get total number of evaluations
(get-total-evaluation-count u1)

;; Get course details
(retrieve-course-information u1)
```

## Security Features

- **Access Control**: Multi-tiered permission system
- **Duplicate Prevention**: One evaluation per student per course
- **Data Validation**: Input validation for all user-submitted data
- **Immutable Records**: Blockchain-based storage ensures evaluation integrity

## Best Practices

1. **Course Setup**: Always enroll students before opening evaluations
2. **Evaluation Periods**: Use `modify-course-evaluation-status` to control evaluation windows
3. **Data Quality**: Encourage meaningful written feedback alongside numerical ratings
4. **Access Management**: Regularly review instructor assignments and student enrollments

## Limitations

- Maximum course name length: 100 ASCII characters
- Maximum feedback length: 500 UTF-8 characters
- One evaluation per student per course (no updates allowed)
- Rating scale fixed at 1-5