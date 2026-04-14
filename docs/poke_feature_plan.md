# Poke Feature Plan

## Overview

After 9 PM in a challenge's timezone, group members can "poke" anyone who hasn't completed their reading for the day. The poked user receives a push notification reminding them to read. Each user can only be poked once per day per poker, and only users with push notifications enabled are pokeable.

## Database

### New migration: `create_pokes`

```
pokes
  - poker_id    (integer, references users, not null)
  - pokee_id    (integer, references users, not null)
  - challenge_id (integer, references challenges, not null)
  - poked_on    (date, not null)
  - created_at  (datetime)
  - updated_at  (datetime)

  index: [poker_id, pokee_id, challenge_id, poked_on], unique: true
```

The unique index enforces the "once per day per person per challenge" rule at the DB level.

## Model

### `Poke` (`app/models/poke.rb`)

```ruby
class Poke < ApplicationRecord
  belongs_to :poker, class_name: "User"
  belongs_to :pokee, class_name: "User"
  belongs_to :challenge

  validates :poked_on, presence: true
  validates :poker_id, uniqueness: { scope: [ :pokee_id, :challenge_id, :poked_on ] }
  validate :cannot_poke_self

  private

  def cannot_poke_self
    errors.add(:base, "Cannot poke yourself") if poker_id == pokee_id
  end
end
```

Add `has_many :sent_pokes, class_name: "Poke", foreign_key: :poker_id` and `has_many :received_pokes, class_name: "Poke", foreign_key: :pokee_id` to `User`.

## Controller

### `PokesController` (`app/controllers/pokes_controller.rb`)

Single action: `create`

- Params: `pokee_id`, `group_id`
- Authenticate current user
- Look up the group and challenge
- Server-side validations:
  1. Current time in challenge timezone is >= 9 PM
  2. Pokee has not completed today's reading
  3. Pokee has at least one `PushSubscription`
  4. No existing `Poke` for this poker/pokee/challenge/date combo
  5. Poker is a member of the same group
  6. Poker is not poking themselves
- On success: create the `Poke` record, enqueue `SendPokeNotificationJob`
- Respond with Turbo Stream to swap the poke button with a "poked" indicator

## Route

```ruby
resources :groups, only: [] do
  resources :pokes, only: [ :create ]
end
```

This gives us `POST /groups/:group_id/pokes` with `pokee_id` in params.

## Background Job

### `SendPokeNotificationJob` (`app/jobs/send_poke_notification_job.rb`)

- Receives `poke_id`
- Loads the Poke with associations
- Sends push notification to all of the pokee's `PushSubscription`s
- Notification text: `"#{poker.username} is reminding you to read today!"`
- Icon: `/icons/icon-192x192.png`
- Data path: `/` (opens the reading page)
- Handles `WebPush::ExpiredSubscription` by destroying the subscription
- Same VAPID pattern as `SendReadingNotificationJob`

## UI Changes

### Group component (`group_component.html.erb`)

In the member list, for each enrollment row, replace/augment the checkbox column:

- **If the user has read today:** Show the green checkbox (existing behavior)
- **If the user has NOT read today AND it's after 9 PM AND the user is not the current user AND the pokee has push subscriptions:**
  - If NOT already poked today: Show a tappable "poke" icon (a finger-pointing or bell icon)
  - If already poked today: Show a muted/disabled "poked" indicator (greyed out icon or small "Poked" text)
- **If it's before 9 PM or the user has no push subscriptions:** Just show the unchecked checkbox (no poke icon)

The poke button should be a Turbo-enabled form that posts to `group_pokes_path(group, pokee_id: user.id)`.

### Group component (`group_component.rb`)

Add helper methods:

```ruby
def after_9pm?
  now = Time.current.in_time_zone(group.challenge.timezone)
  now.hour >= 21
end

def pokeable?(user)
  return false if user == current_user
  return false if has_read_today?(user)
  return false unless after_9pm?
  return false unless user.push_subscriptions.exists?
  true
end

def already_poked_today?(user)
  Poke.exists?(
    poker: current_user,
    pokee: user,
    challenge: group.challenge,
    poked_on: today_in_challenge_timezone
  )
end
```

### Turbo Stream response

After a successful poke, return a Turbo Stream that replaces the poke button for that user with the "poked" state, so the UI updates without a full page reload.

## i18n

Add to both `en.yml` and `de.yml`:

```yaml
pokes:
  poke: "Poke"
  poked: "Poked"
  notification: "%{username} is reminding you to read today!"
  already_poked: "Already poked today"
  too_early: "Poke is available after 9 PM"
  no_push: "This user doesn't have push notifications enabled"
  success: "Poke sent!"
```

## Implementation Order

1. Migration + model + factory
2. Model specs (uniqueness, validations, cannot-poke-self)
3. Job + job specs (mirrors `SendReadingNotificationJob` pattern)
4. Controller + request specs (all guard conditions)
5. Component helpers (`pokeable?`, `already_poked_today?`, `after_9pm?`)
6. UI changes in `group_component.html.erb` with Turbo Stream
7. i18n keys in both locale files
8. Component specs / system tests

## Edge Cases

- **User completes reading after being poked:** The poke record stays — no harm, it was valid when sent.
- **Multiple groups in same challenge:** Poke is scoped to challenge, not group. So if you poke someone in Group A, you can't poke them again from Group B on the same day.
- **Challenge with no reading today:** `pokeable?` returns false because `has_read_today?` checks for `todays_reading` which will be nil.
- **N+1 queries:** Preload `push_subscriptions` existence and today's pokes in the component to avoid per-member queries. Can use a single query to get all pokee_ids that have been poked today and all user_ids with push subscriptions for the group members.
