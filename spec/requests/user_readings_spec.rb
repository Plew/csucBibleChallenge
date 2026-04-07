require "rails_helper"

RSpec.describe "UserReadings", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, timezone: "UTC") }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:reading) { create(:reading, challenge: challenge, scheduled_date: Date.today) }

  describe "POST /user_readings" do
    before { login_via_session(user) }

    it "enqueues SendReadingNotificationJob" do
      expect {
        post user_readings_path, params: { reading_id: reading.id }
      }.to have_enqueued_job(SendReadingNotificationJob).with(user.id, reading.id)
    end

    it "enqueues CheckBadgesJob" do
      expect {
        post user_readings_path, params: { reading_id: reading.id }
      }.to have_enqueued_job(CheckBadgesJob).with(user.id, challenge.id)
    end
  end
end
