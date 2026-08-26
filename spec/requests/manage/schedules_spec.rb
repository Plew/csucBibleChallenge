# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Manage::Schedules", type: :request do
  let(:creator) { create(:user, can_create_challenges: true) }
  let(:other_user) { create(:user) }
  let(:start_date) { Date.new(2026, 9, 1) } # Tuesday

  let!(:challenge) do
    create(:challenge,
           creator: creator,
           name: "Gospels Challenge",
           start_date: start_date,
           end_date: start_date + 27.days,
           chapters_per_day: 1)
  end

  # Create 4 consecutive chapters (e.g., Matthew 1..4)
  let!(:readings) do
    (1..4).map do |ch|
      create(:reading, challenge: challenge, book_number: 40, chapter_number: ch, scheduled_date: start_date + (ch - 1).days)
    end
  end

  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /challenges/:challenge_id/manage/schedule/edit" do
    context "when logged in as challenge creator" do
      before do
        log_in_as(creator)
      end

      it "returns http success and displays schedule form" do
        get edit_challenge_manage_schedule_path(challenge)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Reading Schedule")
        expect(response.body).to include("Chapters Per Day")
        expect(response.body).to include("Reading Days of the Week")
      end
    end

    context "when logged in as unauthorized user" do
      before do
        log_in_as(other_user)
      end

      it "denies access" do
        get edit_challenge_manage_schedule_path(challenge)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/schedule" do
    before do
      log_in_as(creator)
    end

    it "updates chapters_per_day and automatically reschedules readings" do
      patch challenge_manage_schedule_path(challenge), params: {
        challenge: {
          start_date: start_date,
          chapters_per_day: 2,
          skip_days_of_week: []
        }
      }

      expect(response).to redirect_to(edit_challenge_manage_schedule_path(challenge))
      follow_redirect!
      expect(flash[:notice]).to be_present

      challenge.reload
      expect(challenge.chapters_per_day).to eq(2)

      # 4 chapters @ 2/day = 2 reading days (Sept 1: Matt 1&2, Sept 2: Matt 3&4)
      readings_by_date = challenge.readings.reload.group_by(&:scheduled_date)
      expect(readings_by_date.keys.count).to eq(2)
      expect(readings_by_date[start_date].map(&:chapter_number).sort).to eq([1, 2])
      expect(readings_by_date[start_date + 1.day].map(&:chapter_number).sort).to eq([3, 4])
      expect(challenge.end_date).to eq(start_date + 1.day)
    end

    it "updates reading_days and reschedules readings" do
      friday = Date.new(2026, 9, 4) # Friday
      challenge.update!(start_date: friday)

      patch challenge_manage_schedule_path(challenge), params: {
        challenge: {
          start_date: friday,
          chapters_per_day: 1,
          reading_days: ["1", "2", "3", "4", "5"] # Monday through Friday
        }
      }

      challenge.reload
      expect(challenge.skip_days_of_week_list).to eq([0, 6])

      scheduled_dates = challenge.readings.reload.order(:scheduled_date).pluck(:scheduled_date)
      expect(scheduled_dates).to eq([
        Date.new(2026, 9, 4),
        Date.new(2026, 9, 7),
        Date.new(2026, 9, 8),
        Date.new(2026, 9, 9)
      ])
      expect(challenge.end_date).to eq(Date.new(2026, 9, 9))
    end

    it "updates skip_days_of_week and reschedules readings" do
      friday = Date.new(2026, 9, 4) # Friday
      challenge.update!(start_date: friday)

      patch challenge_manage_schedule_path(challenge), params: {
        challenge: {
          start_date: friday,
          chapters_per_day: 1,
          skip_days_of_week: ["0", "6"] # Skip Sunday, Saturday
        }
      }

      challenge.reload
      expect(challenge.skip_days_of_week_list).to eq([0, 6])

      scheduled_dates = challenge.readings.reload.order(:scheduled_date).pluck(:scheduled_date)
      # Friday Sept 4 (Day 1)
      # Sat Sept 5 (Skipped)
      # Sun Sept 6 (Skipped)
      # Mon Sept 7 (Day 2)
      # Tue Sept 8 (Day 3)
      # Wed Sept 9 (Day 4)
      expect(scheduled_dates).to eq([
        Date.new(2026, 9, 4),
        Date.new(2026, 9, 7),
        Date.new(2026, 9, 8),
        Date.new(2026, 9, 9)
      ])
      expect(challenge.end_date).to eq(Date.new(2026, 9, 9))
    end

    it "updates skip_dates_text and reschedules readings" do
      patch challenge_manage_schedule_path(challenge), params: {
        challenge: {
          start_date: start_date,
          chapters_per_day: 1,
          skip_dates_text: "2026-09-02" # Skip Day 2
        }
      }

      challenge.reload
      expect(challenge.skip_dates_list).to eq([Date.new(2026, 9, 2)])

      scheduled_dates = challenge.readings.reload.order(:scheduled_date).pluck(:scheduled_date)
      # Day 1: Sept 1
      # Sept 2: Skipped
      # Day 2: Sept 3
      # Day 3: Sept 4
      # Day 4: Sept 5
      expect(scheduled_dates).to eq([
        Date.new(2026, 9, 1),
        Date.new(2026, 9, 3),
        Date.new(2026, 9, 4),
        Date.new(2026, 9, 5)
      ])
    end
  end
end
