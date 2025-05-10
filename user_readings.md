# User Check-in Date Management PRD

**Version:** 1.0
**Date:** #{Time.now.strftime('%Y-%m-%d')}
**Author/Owner:** [Your Name/Team]

## 1. Introduction / Overview

This PRD covers the data requirements for user checkins and some common data aggregation needs

## 4. User Stories / Use Cases

*(Describe specific scenarios of how API clients will interact with this feature. Format: "As an [type of API client/user role], I want to [perform an action via API] so that [a benefit can be achieved].")*

*   **US-1:** As an API client (representing a user), I want to be able to mark a reading as complete via an API call so that the user's progress can be tracked.
*   **US-1:** As an API client (representing a user), I want to be able to mark a reading as not completed via an API call so that an accidental check-in can be undone.
*   **US-2:** As an API client (representing a user), I want to be able to retrieve the check-in status for readings via an API call so that the user's application can display what they've already read.

## 5. Proposed Features / Requirements

### 5.1. Functional Requirements

*(Detail the specific API functionalities. What should the system do?)*

*   **FR-1:** The system must provide an API endpoint for an authenticated user to mark a specific reading (e.g., a chapter or a predefined section) as "read" or "complete".
*   **FR-2:** The system must persist this check-in status for the user (a UserReading)
*   **FR-3:** The system must provide an API endpoint for an authenticated user to un-check a reading if marked by mistake.
*   **FR-4:** The system must provide an API endpoint to retrieve the check-in status of readings for an authenticated user.
*   **FR-5:** The API must enforce that users can only check or uncheck a reading on the date of the reading, as indicated by the timezone of the challenge the reading is part of.

## 6. Implementation To-Do List (API Focused)

- [ ] **Data Model:**
    - [ ] Ensure `UserReading` model can store check-in status (e.g., has `completed_at` timestamp or boolean `completed` attribute, and already belongs_to `User` and `Reading`).
- [ ] **API Endpoints & Business Logic:**
    - [ ] Design and implement an API endpoint to mark a reading as complete (creates or updates a `UserReading` record).
    - [ ] Design and implement an API endpoint to un-mark a reading (updates or destroys a `UserReading` record).
    - [ ] Design and implement an API endpoint to retrieve a user's check-in status for one or more readings.
    - [ ] Implement core logic: users can only check/uncheck readings via the API on the date of the reading (respecting challenge timezone, acting on `UserReading`).
- [ ] **Testing:**
    - [ ] Write model tests for `UserReading` (focus on check-in related attributes/logic).
    - [ ] Write request/controller tests for the API endpoints (marking complete, un-marking, retrieving status).
    - [ ] Write tests for the timezone-based restriction logic within the API.
    - [ ] Write API integration tests for the check-in/check-out and status retrieval flows. 