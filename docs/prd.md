# Product Requirements Document: Reading Challenge API

## 1. Introduction

This document outlines the requirements for a Reading Challenge API. The API will allow for the creation and management of users, reading challenges, and user progress within those challenges.

## 2. Goals

*   Enable the creation and management of reading challenges.
*   Allow users to register and participate in challenges.
*   Track user progress through scheduled readings within challenges.
*   Provide a flexible system for users to optionally join groups within challenges.

## 3. User Stories

*   As a **Challenge Creator/Administrator**, I want to create challenges with scheduled readings so users have structured content.
*   As a **Challenge Creator/Administrator**, I want to invite or add users to my challenge so they can participate.
*   As a **User**, I want to register for the service to access reading challenges.
*   As a **User**, I want to have a unique username, email, and password for authentication.
*   As a **User**, I want to join a challenge (or be invited to one) so I can participate in its readings.
*   As a **User**, I want to optionally join a group within a challenge to participate with others.
*   As a **User**, I want to see the scheduled readings for a challenge, including their date and title.
*   As a **User**, I want to mark a reading as "read" to track my progress.
*   As a **User**, I want to unmark a reading if I made a mistake or want to re-read it.

## 4. Proposed Features

### 4.1. User Management
- [x] User registration with a unique email and unique username.
- [x] Password management will utilize Rails' `has_secure_password`.
*   Password reset functionality is out of scope for the initial version.

### 4.2. Challenge Management
- [x] Create Challenges
- [x] Add users to a Challenge (Invite aspect not implemented)
- [x] Challenges are a collection of scheduled readings (Implemented via Readings model)
- [x] Define Readings for a Challenge (date, title) (Implemented via Readings model & API)

### 4.3. Participation
- [x] Users can join Challenges (or be enrolled)
- [x] Users can optionally join Groups within a Challenge (Implemented via UserChallengeEnrollment group_id & API)
- [x] A Challenge can have multiple Groups (Implemented via Group model & API)
- [x] A User can be part of a Group within a Challenge (Implemented via UserChallengeEnrollment group_id & API)

### 4.4. Progress Tracking
- [x] Track User's progress on Readings (e.g., `user_readings` table)
- [x] Users can "check" (mark as read) a Reading (Implemented via UserReadings create API)
- [x] Users can "uncheck" a Reading (Implemented via UserReadings destroy API)

## 5. Data Model (Initial Thoughts)

*   **Users**:
    - [x] `id`
    - [x] `username` (must be unique)
    - [x] `email` (must be unique)
    - [x] `password_digest` (for use with `has_secure_password`)
*   **Challenges**:
    - [x] `id`
    - [x] `name`
    - [x] `start_date`
    - [x] `end_date`
    - [x] `timezone` (string, IANA timezone name, e.g., "America/New_York")
    - [ ] *(other attributes as needed, e.g., creator_user_id)*
*   **Readings**:
    - [x] `id`
    - [x] `challenge_id` (belongs to one challenge)
    - [x] `book_number` (integer, required)
    - [x] `chapter_number` (integer, required)
    - [x] `title`
    - [x] `scheduled_date`
*   **Groups**:
    - [x] `id`
    - [x] `challenge_id` (belongs to one challenge)
    - [x] `name`
*   **UserChallengeEnrollments** (for users joining challenges):
    - [x] `id`
    - [x] `user_id`
    - [x] `challenge_id`
    - [x] `group_id` (optional, if user joins a group in this challenge)
*   **UserReadings** (for tracking progress):
    - [x] `id`
    - [x] `user_id`
    - [x] `reading_id`
    - [x] `completed_on` (date when checked)
*   **Verses**:
    - [x] `id` (implicitly created by Rails)
    - [x] `version` (string, e.g., "KJV", "ESV") - indexed
    - [x] `book_number` (integer) - indexed
    - [x] `chapter_number` (integer) - indexed
    - [x] `verse_number` (integer) - indexed
    - [x] `verse_text` (text or string)

---

## 6. Non-Functional Requirements

### 6.1. Testing
- [x] Unit tests will be written using RSpec. (User, Challenge, UserChallengeEnrollment, Reading, Group, UserReading models covered)
- [x] Model tests should cover: (All current models covered for these where applicable)
    - [x] Validations (e.g., presence, uniqueness, format).
    - [x] Associations (e.g., `has_many`, `belongs_to`). (All current associations covered)
    - [x] Core model logic and methods.
- [x] Request tests will be written using RSpec for API endpoints. (All current API endpoints covered)

---

This is a starting point. We can refine and add more details as we go. 