# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckBadgesJob, type: :job do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }

  it "calls BadgeAwarder" do
    awarder = instance_double(BadgeAwarder, call: [])
    expect(BadgeAwarder).to receive(:new).with(user, challenge).and_return(awarder)

    CheckBadgesJob.perform_now(user.id, challenge.id)
  end

  it "handles missing user gracefully" do
    expect { CheckBadgesJob.perform_now(-1, challenge.id) }.not_to raise_error
  end

  it "handles missing challenge gracefully" do
    expect { CheckBadgesJob.perform_now(user.id, -1) }.not_to raise_error
  end

  it "writes newly awarded badges to cache" do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
    allow(Rails).to receive(:cache).and_return(memory_store)

    challenge_with_dates = create(:challenge, start_date: 60.days.ago.to_date, end_date: 60.days.from_now.to_date)
    create(:user_challenge_enrollment, user: user, challenge: challenge_with_dates)
    7.times do |i|
      date = (7 - i).days.ago.to_date
      reading = create(:reading, challenge: challenge_with_dates, scheduled_date: date, book_number: 1, chapter_number: i + 1)
      create(:user_reading, user: user, reading: reading, completed_on: date)
    end

    CheckBadgesJob.perform_now(user.id, challenge_with_dates.id)

    cached = Rails.cache.read("badge_notifications/#{user.id}")
    expect(cached).to include("streak_7")
  end
end
