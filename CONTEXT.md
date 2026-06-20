# Bible Reading Challenge

A Rails app for running Bible reading challenges: people enroll in a challenge, mark daily chapters complete, and are ranked on how much and how punctually they read.

## Language

### Participation

**Challenge**:
A time-bound Bible reading plan with a fixed set of scheduled daily readings, its own timezone, and a single creator.

**Reading**:
One scheduled chapter on a specific date within a challenge. Identified by book/chapter and a `scheduled_date`.
_Avoid_: chapter (when precision matters), assignment

**Reader**:
A user enrolled in a challenge (via `UserChallengeEnrollment`). On the Top Readers page, "reader" is narrowed to **a user who has completed at least one reading** — people who joined but never read are excluded.
_Avoid_: participant, member (use these for raw enrollment regardless of activity)

**Completion** (UserReading):
The record that a reader marked a given reading done, stamped with `completed_on` (a date, in the challenge's timezone).

**Missed reading**:
A reading whose `scheduled_date` is strictly **before today** (in the challenge timezone) that the reader has **not** completed. Today's reading is never "missed" — it can still be completed on time. Future readings are not missed. The Catch Up page lists a reader's missed readings.
_Avoid_: "behind", "overdue" (acceptable in prose, but "missed reading" is canonical)

### Groups & Sprints

**Group**:
A named sub-team within a challenge that members join (via `UserGroupEnrollment`) and that competes in sprints. A member belongs to **at most one group per challenge** — an invariant the UI assumes, though the schema does not enforce it. Deleting a group leaves its former members enrolled in the challenge but group-less, and preserves past sprint-winner history (the winning group's name is denormalized onto the `sprint_winner` record).
_Avoid_: team, squad

**Sprint**:
A bounded date window inside a challenge during which **groups** compete on completion % and on-time %, scored **only over readings scheduled within the window**. Because scoring is window-scoped, a sprint gives a reader who has fallen behind a **fresh start** — readings missed before the sprint do not count against them during it. The top group by completion % (on-time % as tie-breaker) wins; ties yield co-winners; sprints within a challenge cannot overlap.
_Avoid_: contest, round, season

### Multi-challenge

**Active challenge**:
The single challenge that drives a logged-in user's single-challenge surfaces (reading page, bottom nav, daily context) when they hold multiple enrollments. Resolved as: the enrollment whose challenge is **in progress today** (`start_date <= today <= end_date`); if several are in progress, the **most-recently-joined**; if none is in progress (between challenges), the most-recently-joined enrollment overall. Replaces the legacy `current_user.challenges.first`. A manual switcher may be added later.
_Avoid_: "current challenge" (ambiguous), "first challenge"

### Scoring

**Completion percentage**:
Of the readings scheduled *up to today* (in the challenge timezone), the fraction a reader has completed. Denominator is scheduled-to-date, not the whole challenge.

**On-time percentage** (a.k.a. on-schedule):
Of the readings scheduled *up to today*, the fraction the reader completed **on their exact scheduled date** (`DATE(completed_on) = scheduled_date`).
- Completing a reading **early counts as NOT on-time**, and so does late. Only same-day counts.
- Denominator is scheduled-to-date (NOT the reader's completion count), so **on-time % can never exceed completion %**; skipping a day lowers it.
_Avoid_: punctuality score, "of what they read" — those imply a completions-based denominator, which this project does NOT use.

**Top Readers ranking**:
Default ordering of readers by completion % desc, then on-time % desc, then most-recent completion desc.

### Permission tiers

**Global admin**:
A site-wide admin (`User#admin?`). Governs the `/admin/...` namespace.

**Challenge creator**:
The single user who owns a challenge (`Challenge#owned_by?`, `creator_id`).
_Avoid_: owner (acceptable as alias, but "creator" is canonical)

**Challenge admin**:
A user granted the `"admin"` role on a specific challenge via `UserChallengeEnrollment` — not a global admin.

**Manageable-by**:
The union that can manage a challenge: global admin OR creator OR challenge admin (`Challenge#manageable_by?`). Governs the `/challenges/:id/manage/...` namespace, including the Top Readers page.

**Management hub**:
The single management interface for a challenge, living in the `/challenges/:id/manage` namespace (NOT the `/admin` namespace). It is the one place creators, challenge admins, and global admins all manage a challenge — there is no separate management UI for global admins. The `/admin/challenges` area is reserved for cross-challenge listing/operations, not per-challenge management.
_Avoid_: "Manage Challenge page", "admin challenge page" (ambiguous — name the hub)

## Flagged ambiguities

- **"Admin"** is overloaded: it can mean *global admin* or *per-challenge challenge-admin*. When a feature should be visible to "any admin," confirm whether it means global admins only or the full `manageable_by?` set. The Top Readers page uses `manageable_by?`.
- **"On-time %"** sounds like "of what you read, how much was punctual," but the project defines it against scheduled-to-date. See Scoring above.

## Example dialogue

**Dev:** "The Top Readers page should list all the readers in the challenge."
**Expert:** "All *active* readers — anyone who's completed at least one chapter. Don't show people sitting at 0%."
**Dev:** "And on-time % is, of the chapters they read, how many were on the day?"
**Expert:** "No — it's of the chapters scheduled so far. If they skipped a day, that counts against their on-time %, even for days they never read. So on-time can't be higher than completion."
**Dev:** "Who can see the page — just the creator?"
**Expert:** "Any admin: site admins, the creator, or a challenge admin. Same as the rest of the manage area."
