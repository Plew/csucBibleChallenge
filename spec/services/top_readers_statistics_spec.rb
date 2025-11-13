# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TopReadersStatistics, type: :service do
  let(:timezone) { 'Central Time (US & Canada)' }
  let(:challenge) { create(:challenge, start_date: Date.current - 20, end_date: Date.current + 10, timezone: timezone) }
  let!(:readings) do
    dates = (Date.current - 19..Date.current - 10).to_a
    create_list(:reading, 10, challenge: challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
  end

  describe '.call' do
    context 'with no users' do
      it 'returns an empty array' do
        result = described_class.call(challenge: challenge)
        expect(result).to eq([])
      end
    end

    context 'with users who have not completed any chapters' do
      let!(:users) { create_list(:user, 3) }
      let!(:enrollments) do
        users.map { |user| create(:user_challenge_enrollment, user: user, challenge: challenge) }
      end

      it 'filters out users with zero completed chapters' do
        result = described_class.call(challenge: challenge)
        expect(result).to eq([])
      end
    end

    context 'with users who have completed chapters' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:user3) { create(:user) }
      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: challenge) }
      let!(:enrollment3) { create(:user_challenge_enrollment, user: user3, challenge: challenge) }

      before do
        # user1 completes all 10 readings (100%)
        readings.each do |reading|
          create(:user_reading, user: user1, reading: reading, completed_on: reading.scheduled_date)
        end

        # user2 completes 5 readings (50%)
        readings.first(5).each do |reading|
          create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date)
        end

        # user3 completes 7 readings (70%)
        readings.first(7).each do |reading|
          create(:user_reading, user: user3, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'returns users sorted by completion percentage' do
        result = described_class.call(challenge: challenge)

        expect(result.length).to eq(3)
        expect(result[0][:user]).to eq(user1)
        expect(result[1][:user]).to eq(user3)
        expect(result[2][:user]).to eq(user2)
      end

      it 'filters out users with less than 50% completion' do
        # Create a user with less than 50% completion
        user4 = create(:user)
        create(:user_challenge_enrollment, user: user4, challenge: challenge)
        readings.first(4).each do |reading|
          create(:user_reading, user: user4, reading: reading, completed_on: reading.scheduled_date)
        end

        result = described_class.call(challenge: challenge)

        # Should only include users with 50%+ completion
        expect(result.map { |r| r[:user] }).not_to include(user4)
        expect(result.length).to eq(3)
      end

      it 'calculates correct completion percentages' do
        result = described_class.call(challenge: challenge)

        expect(result[0][:completion_percentage]).to eq(100)
        expect(result[1][:completion_percentage]).to eq(70)
        expect(result[2][:completion_percentage]).to eq(50)
      end

      it 'includes chapters completed and scheduled counts' do
        result = described_class.call(challenge: challenge)

        expect(result[0][:chapters_completed]).to eq(10)
        expect(result[0][:chapters_scheduled]).to eq(10)
        expect(result[1][:chapters_completed]).to eq(7)
        expect(result[1][:chapters_scheduled]).to eq(10)
      end

      it 'includes total chapters read' do
        result = described_class.call(challenge: challenge)

        expect(result[0][:total_chapters_read]).to eq(10)
        expect(result[1][:total_chapters_read]).to eq(7)
        expect(result[2][:total_chapters_read]).to eq(5)
      end
    end

    context 'with on-schedule percentage calculation' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      it 'calculates 50% when 5 out of 10 readings completed on schedule' do
        # Complete at least 50% (5 out of 10) all on schedule
        readings.first(5).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
        end

        result = described_class.call(challenge: challenge)
        # 5 on-schedule out of 10 total scheduled = 50%
        expect(result[0][:on_schedule_percentage]).to eq(50)
      end

      it 'calculates correct percentage when some readings are late' do
        # Complete 6 total (60%, above 50% threshold) - 3 on time and 3 late
        readings.first(6).each_with_index do |reading, index|
          if index < 3
            # First 3 on time
            create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
          else
            # Last 3 late
            create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date + 2.days, created_at: reading.scheduled_date + 2.days)
          end
        end

        result = described_class.call(challenge: challenge)
        # 3 on-schedule out of 10 total scheduled = 30%
        expect(result[0][:on_schedule_percentage]).to eq(30)
      end

      it 'returns 0 when all readings are late' do
        # Complete at least 50% (5 out of 10) but all late
        readings.first(5).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date + 1.day, created_at: reading.scheduled_date + 1.day)
        end

        result = described_class.call(challenge: challenge)
        expect(result[0][:on_schedule_percentage]).to eq(0)
      end
    end

    context 'with many users' do
      let!(:users) { create_list(:user, 60) }
      let!(:enrollments) do
        users.map { |user| create(:user_challenge_enrollment, user: user, challenge: challenge) }
      end

      before do
        # Have all 60 users complete at least 50% (5 readings)
        users.each do |user|
          readings.first(5).each do |reading|
            create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
          end
        end
      end

      it 'returns all users who have completed readings with 50%+ completion' do
        result = described_class.call(challenge: challenge)
        expect(result.length).to eq(60)
      end
    end

    context 'with groups' do
      let(:group) { create(:group, challenge: challenge, name: 'Test Group') }
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
      let!(:group_enrollment) { create(:user_group_enrollment, user: user, group: group) }

      before do
        # Complete at least 50% (5 readings)
        readings.first(5).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'includes group name for users in groups' do
        result = described_class.call(challenge: challenge)
        expect(result[0][:group_name]).to eq('Test Group')
      end
    end

    context 'with users not in groups' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      before do
        # Complete at least 50% (5 readings)
        readings.first(5).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'returns nil group_name for users not in groups' do
        result = described_class.call(challenge: challenge)
        expect(result[0][:group_name]).to be_nil
      end
    end

    context 'with avatar handling' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      before do
        # Complete at least 50% (5 readings)
        readings.first(5).each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'includes avatar_url key in results' do
        result = described_class.call(challenge: challenge)
        expect(result[0]).to have_key(:avatar_url)
      end
    end

    context 'respecting challenge timezone' do
      let(:early_timezone_challenge) { create(:challenge, start_date: Date.current - 15, end_date: Date.current + 5, timezone: 'Auckland') }
      let!(:early_readings) do
        dates = (Date.current - 14..Date.current - 10).to_a
        create_list(:reading, 5, challenge: early_timezone_challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
      end
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: early_timezone_challenge) }

      before do
        early_readings.each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'uses challenge timezone for date calculations' do
        result = described_class.call(challenge: early_timezone_challenge)

        # Should calculate based on Auckland timezone
        expect(result).not_to be_empty
        expect(result[0][:chapters_completed]).to eq(5)
      end
    end

    context 'sorting with tiebreaker by on-time percentage then most recent reading' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:user3) { create(:user) }
      let!(:user4) { create(:user) }
      let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: challenge) }
      let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: challenge) }
      let!(:enrollment3) { create(:user_challenge_enrollment, user: user3, challenge: challenge) }
      let!(:enrollment4) { create(:user_challenge_enrollment, user: user4, challenge: challenge) }

      before do
        # All four users have 70% completion (7 out of 10 readings)
        # but different on-time percentages and most recent reading timestamps
        # Note: on-time percentage is calculated as (on_schedule_count / total_scheduled) * 100

        # user1: 70% on-time (7 on time out of 10 scheduled = 70%)
        readings.first(7).each do |reading|
          create(:user_reading, user: user1, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
        end

        # user2: 40% on-time (4 on time out of 10 scheduled = 40%), most recent reading 1 day ago
        readings.first(7).each_with_index do |reading, index|
          if index < 4
            create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
          else
            created_at = index == 6 ? 1.day.ago : (reading.scheduled_date + 2.days)
            create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date + 2.days, created_at: created_at)
          end
        end

        # user3: 40% on-time (4 on time out of 10 scheduled = 40%), most recent reading 3 days ago
        readings.first(7).each_with_index do |reading, index|
          if index < 4
            create(:user_reading, user: user3, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
          else
            created_at = index == 6 ? 3.days.ago : (reading.scheduled_date + 2.days)
            create(:user_reading, user: user3, reading: reading, completed_on: reading.scheduled_date + 2.days, created_at: created_at)
          end
        end

        # user4: 20% on-time (2 on time out of 10 scheduled = 20%)
        readings.first(7).each_with_index do |reading, index|
          if index < 2
            create(:user_reading, user: user4, reading: reading, completed_on: reading.scheduled_date, created_at: reading.scheduled_date)
          else
            create(:user_reading, user: user4, reading: reading, completed_on: reading.scheduled_date + 2.days, created_at: reading.scheduled_date + 2.days)
          end
        end
      end

      it 'sorts users first by completion percentage, then by on-time percentage, then by most recent reading' do
        result = described_class.call(challenge: challenge)

        expect(result.length).to eq(4)

        # All should have 70% completion
        expect(result[0][:completion_percentage]).to eq(70)
        expect(result[1][:completion_percentage]).to eq(70)
        expect(result[2][:completion_percentage]).to eq(70)
        expect(result[3][:completion_percentage]).to eq(70)

        # Should be sorted by on-time percentage first, then by most recent reading
        # user1: 70% on-time (7/10)
        # user2: 40% on-time (4/10), most recent 1 day ago
        # user3: 40% on-time (4/10), most recent 3 days ago
        # user4: 20% on-time (2/10)
        expect(result[0][:user]).to eq(user1)
        expect(result[1][:user]).to eq(user2)
        expect(result[2][:user]).to eq(user3)
        expect(result[3][:user]).to eq(user4)

        # Verify on-time percentages
        expect(result[0][:on_schedule_percentage]).to eq(70)
        expect(result[1][:on_schedule_percentage]).to eq(40)
        expect(result[2][:on_schedule_percentage]).to eq(40)
        expect(result[3][:on_schedule_percentage]).to eq(20)
      end

      it 'includes most_recent_reading_at in the result' do
        result = described_class.call(challenge: challenge)

        expect(result[0]).to have_key(:most_recent_reading_at)
        expect(result[0][:most_recent_reading_at]).to be_present
        expect(result[0][:most_recent_reading_at]).to be_a(ActiveSupport::TimeWithZone)
      end
    end

    context 'with date_range parameter' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
      let(:date_range) { (Date.current - 14)..(Date.current - 11) }

      before do
        # Complete all 10 readings
        readings.each do |reading|
          create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'filters statistics to only include readings within the date range' do
        # date_range covers 4 days
        result = described_class.call(challenge: challenge, date_range: date_range)

        expect(result.length).to eq(1)
        expect(result[0][:chapters_completed]).to eq(4)
        expect(result[0][:chapters_scheduled]).to eq(4)
        expect(result[0][:completion_percentage]).to eq(100)
      end

      it 'returns full stats when date_range is nil' do
        result = described_class.call(challenge: challenge, date_range: nil)

        expect(result.length).to eq(1)
        expect(result[0][:chapters_completed]).to eq(10)
        expect(result[0][:chapters_scheduled]).to eq(10)
      end
    end
  end
end
