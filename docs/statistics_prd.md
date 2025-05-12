# Statistics Product Requirements Document (PRD)

## Overview
A core feature of this application is the ability to display statistics related to progress during a challenge. Statistics are needed at three main levels:

- [x] **User Statistics** – Metrics about individual user progress and engagement.
- [x] **Group Statistics** – Metrics about groups of users, including group progress and dynamics.
- [x] **Challenge Statistics** – Metrics about the challenge as a whole, including aggregate and leaderboard data.

This document outlines the requirements, examples, and implementation considerations for these statistics.

---

## 1. User Statistics
Statistics to be calculated for each user:

- [x] **Overall Completion Rate**: Percentage of readings completed by the user up to the current date, relative to the number of readings that should have been completed by now.
- [x] **Longest Streak**: The maximum number of consecutive days the user completed readings without missing a day.
- [x] **Challenge Join Date**: The date the user joined the challenge.
- [x] **Days Since Last Activity**: Number of days since the user last performed any activity (e.g., reading, check-in).
- [x] **Last Check-in Date**: The most recent date the user checked in.
- [ ] **Last Login Date**: The most recent date the user logged in.  # Not implemented due to missing last_login_at

### Example Queries
- What is Alice's completion rate as of today?
- What is Bob's longest streak?
- When did Carol last check in?

---

## 2. Group Statistics
Statistics to be calculated for each group:

- [x] **Group Size**: Number of users in the group.
- [x] **Last Membership Change Date**: The most recent date a user joined or left the group.
- [x] **Daily Group Check-in Percentage**: For a given date, the percentage of group members who completed the reading.
- [x] **Group Longest Streak**: The maximum number of consecutive days where every member completed the reading.
- [x] **Total Chapters Read by Group**: Aggregate number of chapters read by all group members.
- [x] **Group Completion Percentage**: The average completion percentage of all users in the group over the course of the challenge.

### Example Queries
- What percentage of the "Munich Readers" group completed yesterday's reading?
- What is the group's longest streak?
- How many chapters has the group read in total?

---

## 3. Challenge Statistics
Statistics to be calculated for the challenge as a whole:

- [x] **Total Chapters Read**: Aggregate number of chapters read by all participants.
- [x] **Number of Participants**: Total number of users enrolled in the challenge.
- [x] **Top X Participants by Completion Percentage**: Leaderboard of users ranked by completion rate.
- [x] **Top X Participants by Longest Streak**: Leaderboard of users ranked by their longest streak.

### Example Queries
- How many chapters have been read in total?
- Who are the top 10 participants by completion rate?
- Who has the longest streak?

---

## Implementation Considerations

- [ ] **Persistence**: Most statistics can be calculated on the fly using SQL or ActiveRecord queries. For performance, consider fragment caching or background jobs for expensive calculations.
- [x] **Encapsulation**: Implement dedicated service or query classes for each statistics type (e.g., `UserStatistics`, `GroupStatistics`, `ChallengeStatistics`). This enables modularity, testability, and clear separation of concerns.
- [x] **Testing**: Write comprehensive specs for each statistics class to ensure accuracy and reliability.
- [ ] **Caching**: Use Rails caching strategies (e.g., fragment caching, Russian Doll caching) for statistics that are expensive to compute or frequently accessed.
- [ ] **Indexing**: Ensure relevant database columns are indexed to optimize query performance.

---

## Recommendation
- [ ] **Do not persist statistics unless performance profiling shows a need.**
- [x] **Encapsulate statistics logic in dedicated classes** to keep controllers and models clean and to facilitate testing.
- [x] **Leverage Rails and ActiveRecord** for efficient querying, and use caching as needed.

---

## Next Steps
- [x] Define the API and interface for each statistics class.
- [x] Implement and test statistics classes for user, group, and challenge levels.
- [ ] Integrate statistics into the UI using Hotwire and Tailwind CSS, following mobile-first and DaisyUI guidelines. 