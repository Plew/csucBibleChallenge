# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Challenge Scheduling & Multi-Chapters Per Day", type: :request do
  let(:creator) { create(:user, can_create_challenges: true) }

  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  before do
    log_in_as(creator)
  end

  describe "Creating a challenge with 2 chapters per day" do
    it "schedules 2 chapters per day consecutively" do
      start_date = Date.new(2026, 9, 1) # Tuesday

      post challenges_path, params: {
        challenge: {
          name: "2 Chapters a Day Challenge",
          start_date: start_date,
          timezone: "UTC",
          chapters_per_day: 2
        },
        selected_books: [ "40" ] # Matthew (28 chapters)
      }

      challenge = Challenge.find_by(name: "2 Chapters a Day Challenge")
      expect(challenge).to be_present
      expect(challenge.chapters_per_day).to eq(2)
      expect(challenge.readings.count).to eq(28)

      # 28 chapters @ 2/day = 14 reading days
      readings_by_date = challenge.readings.group_by(&:scheduled_date)
      expect(readings_by_date.keys.count).to eq(14)
      expect(challenge.end_date).to eq(start_date + 13.days)

      # Day 1 should have Matthew 1 & 2
      day1_readings = readings_by_date[start_date]
      expect(day1_readings.map(&:chapter_number).sort).to eq([ 1, 2 ])

      # Day 2 should have Matthew 3 & 4
      day2_readings = readings_by_date[start_date + 1.day]
      expect(day2_readings.map(&:chapter_number).sort).to eq([ 3, 4 ])
    end
  end

  describe "Creating a challenge skipping weekends (Sat & Sun)" do
    it "does not schedule any readings on Saturday or Sunday" do
      # 2026-09-04 is a Friday
      start_date = Date.new(2026, 9, 4)

      post challenges_path, params: {
        challenge: {
          name: "Weekdays Only Challenge",
          start_date: start_date,
          timezone: "UTC",
          chapters_per_day: 1,
          skip_days_of_week: [ "0", "6" ] # Sunday, Saturday
        },
        selected_books: [ "50" ] # Philippians (4 chapters: Phil 1..4)
      }

      challenge = Challenge.find_by(name: "Weekdays Only Challenge")
      expect(challenge).to be_present
      expect(challenge.skip_days_of_week_list).to eq([ 0, 6 ])

      scheduled_dates = challenge.readings.order(:scheduled_date).pluck(:scheduled_date)
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

    it "accepts reading_days params and maps to skip_days_of_week" do
      start_date = Date.new(2026, 9, 4)

      post challenges_path, params: {
        challenge: {
          name: "Mon-Fri Reading Days Challenge",
          start_date: start_date,
          timezone: "UTC",
          chapters_per_day: 1,
          reading_days: [ "1", "2", "3", "4", "5" ] # Mon through Fri
        },
        selected_books: [ "57" ]
      }

      challenge = Challenge.find_by(name: "Mon-Fri Reading Days Challenge")
      expect(challenge).to be_present
      expect(challenge.skip_days_of_week_list).to eq([ 0, 6 ])
      expect(challenge.reading_days_of_week_list).to eq([ 1, 2, 3, 4, 5 ])
    end
  end

  describe "Creating a challenge skipping specific dates" do
    it "skips specific excluded dates from the schedule" do
      start_date = Date.new(2026, 12, 23)

      post challenges_path, params: {
        challenge: {
          name: "Holiday Skip Challenge",
          start_date: start_date,
          timezone: "UTC",
          chapters_per_day: 1,
          skip_dates_text: "2026-12-24, 2026-12-25"
        },
        selected_books: [ "57" ] # Philemon (1 chapter)
      }

      challenge = Challenge.find_by(name: "Holiday Skip Challenge")
      expect(challenge).to be_present
      expect(challenge.skip_dates_list).to eq([ Date.new(2026, 12, 24), Date.new(2026, 12, 25) ])
    end
  end

  describe "Reading page with multiple chapters on the same day" do
    let(:challenge) do
      create(:challenge,
             name: "Multi-Chapter Challenge",
             start_date: Date.current,
             end_date: Date.current + 10.days,
             chapters_per_day: 2)
    end

    let!(:reading1) do
      create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: Date.current)
    end

    let!(:reading2) do
      create(:reading, challenge: challenge, book_number: 40, chapter_number: 2, scheduled_date: Date.current)
    end

    before do
      create(:user_challenge_enrollment, user: creator, challenge: challenge)
      patch switch_active_challenge_path, params: { challenge_id: challenge.id }
    end

    it "renders multi-chapter navigation pills" do
      get reading_path

      expect(response.body).to include("Chapters for Today")
      expect(response.body).to include("0 of 2 completed")
      expect(response.body).to include("Matthew 1")
      expect(response.body).to include("Matthew 2")
    end

    it "marks chapter 1 complete and reflects partial progress" do
      post user_readings_path, params: { reading_id: reading1.id }

      get reading_path

      expect(response.body).to include("1 of 2 completed")
      # Reading 2 should now be ready to read
      expect(response.body).to include("reading_id=#{reading2.id}")
    end
  end

  describe "Reading page on a rest/catch-up day" do
    let(:challenge) do
      create(:challenge,
             name: "Rest Day Challenge",
             start_date: Date.current - 2.days,
             end_date: Date.current + 5.days,
             skip_days_of_week: [ Date.current.wday ]) # Today is a skipped day
    end

    before do
      create(:user_challenge_enrollment, user: creator, challenge: challenge)
      patch switch_active_challenge_path, params: { challenge_id: challenge.id }
    end

    it "renders the Rest / Catch-up Day banner" do
      get reading_path(date: Date.current)

      expect(response.body).to include("Rest / Catch-up Day")
      expect(response.body).to include("No chapters are scheduled for today")
    end
  end
end
