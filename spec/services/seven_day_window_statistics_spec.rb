# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SevenDayWindowStatistics, type: :service do
  let(:timezone) { 'Central Time (US & Canada)' }
  let(:challenge) { create(:challenge, start_date: Date.current - 20, end_date: Date.current + 10, timezone: timezone) }

  describe '.call' do
    context 'with no users' do
      it 'returns an empty array' do
        result = described_class.call(challenge: challenge)
        expect(result).to eq([])
      end
    end

    context 'with users who have not completed any chapters in the 7-day window' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
      let!(:old_reading) { create(:reading, challenge: challenge, scheduled_date: Date.current - 10) }

      before do
        # Complete a reading outside the 7-day window
        create(:user_reading, user: user, reading: old_reading, completed_on: old_reading.scheduled_date)
      end

      it 'filters out users without 100% completion in 7-day window' do
        result = described_class.call(challenge: challenge)
        expect(result).to eq([])
      end
    end

    context 'with users at 100% completion in 7-day window' do
      let!(:user1) { create(:user, name: 'Perfect Reader 1') }
      let!(:user2) { create(:user, name: 'Perfect Reader 2') }
      let!(:user3) { create(:user, name: 'Partial Reader') }
      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: challenge) }
      let!(:enrollment3) { create(:user_challenge_enrollment, user: user3, challenge: challenge) }

      let!(:seven_day_readings) do
        dates = (Date.current - 6..Date.current).to_a
        dates.map { |date| create(:reading, challenge: challenge, scheduled_date: date) }
      end

      before do
        # user1 completes all 7 readings on time (100% completion, 100% on schedule)
        seven_day_readings.each do |reading|
          create(:user_reading, user: user1, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
        end

        # user2 completes all 7 readings but 2 are late (100% completion, ~71% on schedule)
        seven_day_readings.first(5).each do |reading|
          create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
        end
        seven_day_readings.last(2).each do |reading|
          create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date + 1.day, created_at: reading.scheduled_date + 1.day)
        end

        # user3 completes only 5 readings (71% completion)
        seven_day_readings.first(5).each do |reading|
          create(:user_reading, user: user3, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
        end
      end

      it 'returns only users with 100% completion' do
        result = described_class.call(challenge: challenge)

        expect(result.length).to eq(2)
        expect(result.map { |r| r[:name] }).to contain_exactly('Perfect Reader 1', 'Perfect Reader 2')
      end

      it 'sorts by on_schedule_percentage descending' do
        result = described_class.call(challenge: challenge)

        expect(result[0][:name]).to eq('Perfect Reader 1')
        expect(result[0][:on_schedule_percentage]).to eq(100)
        expect(result[1][:name]).to eq('Perfect Reader 2')
        expect(result[1][:on_schedule_percentage]).to be < 100
      end

      it 'includes correct completion percentages' do
        result = described_class.call(challenge: challenge)

        expect(result[0][:completion_percentage]).to eq(100)
        expect(result[1][:completion_percentage]).to eq(100)
      end
    end

    context 'with users at partial completion' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      let!(:seven_day_readings) do
        # Use the challenge timezone's current date: around midnight UTC,
        # Date.current is a day ahead of Central time, which shifts the
        # service's 7-day window and made this spec flaky in nighttime CI runs.
        current_date_in_tz = Time.current.in_time_zone(timezone).to_date
        dates = (current_date_in_tz - 6..current_date_in_tz).to_a
        dates.map { |date| create(:reading, challenge: challenge, scheduled_date: date) }
      end

      before do
        # Complete only 6 out of 7 readings (86% completion)
        seven_day_readings.first(6).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'excludes users without 100% completion' do
        result = described_class.call(challenge: challenge)
        expect(result).to eq([])
      end
    end

    context 'with zero scheduled readings in 7-day window' do
      let(:future_challenge) { create(:challenge, start_date: Date.current + 10, end_date: Date.current + 20, timezone: timezone) }
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: future_challenge) }

      it 'returns empty array' do
        result = described_class.call(challenge: future_challenge)
        expect(result).to eq([])
      end
    end

    context 'respecting challenge timezone' do
      let(:timezone_challenge) { create(:challenge, start_date: Date.current - 15, end_date: Date.current + 5, timezone: 'Auckland') }
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: timezone_challenge) }

      let!(:seven_day_readings) do
        current_date_in_tz = Time.current.in_time_zone('Auckland').to_date
        dates = (current_date_in_tz - 6..current_date_in_tz).to_a
        dates.map { |date| create(:reading, challenge: timezone_challenge, scheduled_date: date) }
      end

      before do
        seven_day_readings.each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'uses challenge timezone for date calculations' do
        result = described_class.call(challenge: timezone_challenge)

        expect(result).not_to be_empty
        expect(result[0][:completion_percentage]).to eq(100)
      end
    end
  end
end
