# Product Requirements Document: Frontend

## 1. Introduction

This document describes the frontend user interface pages for the ReVerse Reading Challenge application. It complements the API PRD by outlining the user-facing views and interactions. All frontend development will adhere to mobile-first design principles and utilize DaisyUI for styling and components.

## 2. General UI Elements

*   **Navbar**: Consistent across most authenticated pages, displaying the application name ("ReVerse") and navigation links (e.g., Home/Today's Reading, Challenges, Profile, Logout).
*   **Footer**: (Optional) May contain copyright information or other relevant links.
*   **Flash Messages**: For success, error, and informational messages (e.g., "Challenge joined successfully," "Invalid login credentials").

## 3. Pages

### 3.1. User Registration Page

*   **Purpose**: Allows new users to create an account.
*   **URL**: `/users/sign_up` (example)
*   **Content and UI Elements**:
    *   Application Logo/Name: "ReVerse".
    *   Heading: "Create your ReVerse Account" or "Sign Up".
    *   Form with the following fields (using DaisyUI `input` components):
        *   Username (text input, required, unique).
        *   Email (email input, required, unique).
        *   Password (password input, required).
        *   Password Confirmation (password input, required, must match Password).
    *   Labels for each input field.
    *   "Register" or "Sign Up" button (DaisyUI `btn btn-primary`).
    *   Link to Login Page: "Already have an account? Log In".
    *   Error messages displayed near respective fields or in a summary area for validation failures (e.g., "Username is already taken," "Email format is invalid," "Passwords do not match").

### 3.2. Login Page

*   **Purpose**: Allows existing users to authenticate and access the application.
*   **URL**: `/users/sign_in` (example)
*   **Content and UI Elements**:
    *   Application Logo/Name: "ReVerse".
    *   Heading: "Log In to ReVerse" or "Sign In".
    *   Form with the following fields (using DaisyUI `input` components):
        *   Email or Username (text input, required).
        *   Password (password input, required).
    *   Labels for each input field.
    *   "Remember me" checkbox (optional).
    *   "Log In" or "Sign In" button (DaisyUI `btn btn-primary`).
    *   Link to Registration Page: "Don't have an account? Sign Up".
    *   Link: "Forgot your password?" (Leads to a "Feature not yet available" message or page, as per API PRD).
    *   Error messages for authentication failures (e.g., "Invalid email/username or password.").

### 3.3. Default Root Page (Today's Reading)

*   **Purpose**: Displays the user's scheduled reading for the current day from their active challenge(s) and allows them to mark it as read. This is typically the first page seen after login.
*   **URL**: `/` or `/dashboard` (example)
*   **Pre-conditions**: User must be logged in.
*   **Content and UI Elements**:
    *   Navbar.
    *   Main Content Area:
        *   **If user has no active challenges or no reading for today**:
            *   Message: "No readings scheduled for today." or "You are not currently enrolled in any active challenges. [Link to Challenges Page]".
        *   **If user has one or more readings scheduled for today** (logic needed to handle multiple active challenges - perhaps a tabbed interface or a list for each challenge's reading for today):
            *   For each reading:
                *   Challenge Name (if multiple challenges have readings today).
                *   Reading Date (e.g., "Today, October 26").
                *   Reading Title (e.g., `reading.title` or "Genesis Chapter 1").
                *   Reference (e.g., Book Name, Chapter Number).
                *   **Reading Content**:
                    *   Display the verses for the chapter/reading (fetched via API, e.g., FR-6 from `prd.md`). This could be a scrollable DaisyUI `card` or similar component.
                *   **Action Button Area** (at the bottom of the reading or page):
                    *   "Mark as Read" button (DaisyUI `btn btn-success`).
                        *   Changes to "Mark as Unread" (DaisyUI `btn btn-outline`) or shows a "Completed" status (e.g., a checkmark icon with text) if already read.
                        *   Button should respect FR-5 (only checkable on the scheduled date, considering challenge timezone). If not checkable, it might be disabled or show a message.
        *   Navigation to view full challenge schedule or other challenges.

### 3.4. Challenges Management Page

*   **Purpose**: Allows users to discover, join, view, and leave reading challenges.
*   **URL**: `/challenges` (example)
*   **Pre-conditions**: User must be logged in.
*   **Content and UI Elements**:
    *   Navbar.
    *   Heading: "Reading Challenges".
    *   Tabs or Sections (using DaisyUI `tabs`):
        *   **"My Challenges" Tab/Section**:
            *   Lists challenges the user is currently enrolled in.
            *   For each challenge (displayed in a DaisyUI `card` or list item):
                *   Challenge Name.
                *   Challenge Dates (Start - End).
                *   Optional: Progress bar or summary (e.g., "X of Y readings completed").
                *   Optional: Group Name if part of a group in that challenge.
                *   Link to view challenge details/schedule.
                *   "Leave Challenge" button (DaisyUI `btn btn-error btn-sm` or icon button, with a confirmation dialog).
            *   Message if user is not in any challenges: "You haven't joined any challenges yet."
        *   **"Available Challenges" Tab/Section**:
            *   Lists publicly available challenges or challenges the user has been invited to (invitation system TBD).
            *   For each challenge (displayed in a DaisyUI `card` or list item):
                *   Challenge Name.
                *   Challenge Dates (Start - End).
                *   Brief Description (if available).
                *   Creator/Administrator (if relevant to display).
                *   "Join Challenge" button (DaisyUI `btn btn-primary btn-sm`).
            *   Message if no challenges are available: "No new challenges available at the moment."
            *   Optional: Search or filter functionality for available challenges.

### 3.5. User Profile / Account Settings Page

*   **Purpose**: Allows users to update their account information, such as username and password.
*   **URL**: `/profile/edit` or `/account/settings` (example)
*   **Pre-conditions**: User must be logged in.
*   **Content and UI Elements**:
    *   Navbar.
    *   Heading: "Account Settings" or "Edit Profile".
    *   DaisyUI `card` or form sections for different settings:
        *   **Update Username**:
            *   Current Username (display text).
            *   Email (display text, typically not changeable without verification).
            *   Input field for New Username (DaisyUI `input`).
            *   "Save Username" or "Update Username" button (DaisyUI `btn`).
        *   **Change Password**:
            *   Input field for Current Password (DaisyUI `input` type password).
            *   Input field for New Password (DaisyUI `input` type password).
            *   Input field for Confirm New Password (DaisyUI `input` type password).
            *   "Change Password" button (DaisyUI `btn`).
    *   Success/error messages for update operations.
    *   Link to logout. 