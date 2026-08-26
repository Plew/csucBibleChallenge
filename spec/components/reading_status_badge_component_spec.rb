require 'rails_helper'

RSpec.describe ReadingStatusBadgeComponent, type: :component do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, timezone: 'UTC', start_date: 1.week.ago, end_date: 1.week.from_now) }
  let(:today) { Date.current }

  it "renders compact badge when read today" do
    reading = create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: today)
    create(:user_reading, user: user, reading: reading)

    render_inline(described_class.new(challenge: challenge, user: user, variant: :compact))

    expect(rendered_content).to include("Read today")
    expect(rendered_content).to include("text-success")
  end

  it "renders detailed badge with chapter name on home page style" do
    create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: today)

    render_inline(described_class.new(challenge: challenge, user: user, variant: :detailed))

    expect(rendered_content).to include("Unread today — Matthew 1")
    expect(rendered_content).to include("text-warning")
  end

  it "renders pill badge for challenge lists" do
    reading = create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: today)
    create(:user_reading, user: user, reading: reading)

    render_inline(described_class.new(challenge: challenge, user: user, variant: :badge))

    expect(rendered_content).to include("badge-success")
    expect(rendered_content).to include("Read today")
  end

  it "renders rest day when no readings scheduled" do
    render_inline(described_class.new(challenge: challenge, user: user, variant: :compact))

    expect(rendered_content).to include("Rest day")
  end
end
