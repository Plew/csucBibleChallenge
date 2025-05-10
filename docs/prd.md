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
- [ ] Invite/add users to a Challenge
- [ ] Challenges are a collection of scheduled readings
- [ ] Define Readings for a Challenge (date, title)

### 4.3. Participation
- [ ] Users can join Challenges (or be enrolled)
- [ ] Users can optionally join Groups within a Challenge
- [ ] A Challenge can have multiple Groups
- [ ] A User can be part of a Group within a Challenge

### 4.4. Progress Tracking
- [ ] Track User's progress on Readings (e.g., `user_readings` table)
- [ ] Users can "check" (mark as read) a Reading
- [ ] Users can "uncheck" a Reading

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
    - [ ] *(other attributes as needed, e.g., creator_user_id)*
*   **Readings**:
    - [ ] `id`
    - [ ] `challenge_id` (belongs to one challenge)
    - [ ] `title`
    - [ ] `scheduled_date`
*   **Groups**:
    - [ ] `id`
    - [ ] `challenge_id` (belongs to one challenge)
    - [ ] `name`
*   **UserChallengeEnrollments** (for users joining challenges):
    - [ ] `id`
    - [ ] `user_id`
    - [ ] `challenge_id`
    - [ ] `group_id` (optional, if user joins a group in this challenge)
*   **UserReadings** (for tracking progress):
    - [ ] `id`
    - [ ] `user_id`
    - [ ] `reading_id`
    - [ ] `completed_at` (timestamp when checked)

---

## 6. Non-Functional Requirements

### 6.1. Testing
- [x] Unit tests will be written using RSpec. (User model covered, Challenge model covered)
- [x] Model tests should cover: (User model covered for these, Challenge model covered for these)
    - [x] Validations (e.g., presence, uniqueness, format).
    - [ ] Associations (e.g., `has_many`, `belongs_to`). (No associations for User/Challenge models yet)
    - [x] Core model logic and methods.
- [x] Request tests will be written using RSpec for API endpoints. (User registration covered, Challenge index/show/create covered)

---

This is a starting point. We can refine and add more details as we go. 