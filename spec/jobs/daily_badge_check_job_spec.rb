# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyBadgeCheckJob, type: :job do
  it "enqueues CheckBadgesJob for each user in active challenges" do
    challenge = create(:challenge, start_date: 1.day.ago.to_date, end_date: 1.day.from_now.to_date)
    user = create(:user)
    create(:user_challenge_enrollment, user: user, challenge: challenge)

    expect {
      DailyBadgeCheckJob.perform_now
    }.to have_enqueued_job(CheckBadgesJob).with(user.id, challenge.id)
  end

  it "does not enqueue jobs for inactive challenges" do
    challenge = create(:challenge, start_date: 30.days.ago.to_date, end_date: 2.days.ago.to_date)
    user = create(:user)
    create(:user_challenge_enrollment, user: user, challenge: challenge)

    expect {
      DailyBadgeCheckJob.perform_now
    }.not_to have_enqueued_job(CheckBadgesJob)
  end
end
