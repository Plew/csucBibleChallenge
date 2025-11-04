# Shared Test Contexts

## Realistic Challenge Context

Located in `realistic_challenge_context.rb`, this shared context creates a complete, realistic Bible reading challenge scenario for testing pages that require actual content.

### What It Creates

- **1 Challenge**: "Test Gospel Reading" (Gospel of John, 21 chapters)
  - Start date: 7 days ago
  - End date: 14 days from now
  - Timezone: Eastern Time (US & Canada)

- **5 Users** with varied activity levels:
  - `primary_user`: 75% completion rate
  - `active_user`: 100% completion rate
  - `moderate_user`: 50% completion rate
  - `casual_user`: 25% completion rate
  - `inactive_user`: 0% completion (no readings)

- **2 Groups**:
  - `primary_group`: "Accountability Partners" (primary_user, active_user, moderate_user)
  - `secondary_group`: "Morning Readers" (active_user, casual_user)

- **5 Group Messages** across both groups
- **21 Readings** (Gospel of John)
- **Varied completed readings** based on each user's activity level

### Usage

#### Basic Usage

```ruby
require 'rails_helper'

RSpec.describe "Some Feature", type: :request do
  include_context 'realistic challenge'

  before do
    login_as(primary_user)
  end

  it "loads the stats page with content" do
    get stats_path
    expect(response).to have_http_status(:success)
  end
end
```

#### Testing Different User Perspectives

```ruby
it "works for highly active users" do
  login_as(active_user)
  get stats_path
  expect(response).to have_http_status(:success)
end

it "works for inactive users" do
  login_as(inactive_user)
  get reading_path
  expect(response).to have_http_status(:success)
end
```

#### Adding Custom Data

You can extend the shared context with additional data specific to your test:

```ruby
include_context 'realistic challenge'

let!(:custom_message) do
  create(:group_message,
    group: primary_group,
    user: primary_user,
    content: "Custom test message"
  )
end

it "includes custom data" do
  login_as(primary_user)
  get group_path(primary_group)
  # Group now has standard messages plus your custom one
end
```

#### Using Factory Traits

```ruby
let!(:encouraging_message) do
  create(:group_message, :encouraging,
    group: primary_group,
    user: primary_user
  )
end
```

### Available Variables

All variables use `let!` for eager evaluation:

**Challenge & Readings:**
- `challenge` - The main challenge
- `readings` - Array of 21 reading records

**Users:**
- `primary_user` - Main test user (75% completion)
- `active_user` - Highly engaged user (100% completion)
- `moderate_user` - Medium engagement (50% completion)
- `casual_user` - Low engagement (25% completion)
- `inactive_user` - No activity (0% completion)

**Enrollments:**
- `primary_enrollment`, `active_enrollment`, etc.

**Groups:**
- `primary_group` - "Accountability Partners"
- `secondary_group` - "Morning Readers"

**Group Enrollments:**
- `primary_group_enrollments` - Array of enrollments
- `secondary_group_enrollments` - Array of enrollments

**Messages & Completions:**
- `group_messages` - Array of 5 messages
- `completed_readings` - Array of user_reading records

### Example Spec

See `spec/requests/pages/navigation_spec.rb` for a complete working example.

### Performance

- Each spec file gets a clean database (transactional fixtures)
- Data is created fresh for each spec file
- Typical setup time: ~100-200ms per spec file
- 17 example specs run in ~2 seconds

### Tips

1. Use `login_as(user)` to test with different user perspectives
2. Add `let!` overrides to customize data per spec
3. Use factory traits for common variations
4. Remember: data doesn't persist across spec files (transactional fixtures)
