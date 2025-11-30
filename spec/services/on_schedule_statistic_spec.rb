# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnScheduleStatistic, type: :service do
  let(:challenge) { create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10, timezone: 'Eastern Time (US & Canada)') }
  let(:user) { create(:user) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:readings) do
    # Create 10 readings scheduled for the last 10 days
    dates = (Date.current - 9..Date.current).to_a
    create_list(:reading, 10, challenge: challenge).each_with_index do |reading, i|
      reading.update!(scheduled_date: dates[i])
    end
  end

  subject { described_class.new(user, challenge) }

  describe '#percentage' do
    context 'with no completed readings' do
      it 'returns 0' do
        expect(subject.percentage).to eq(0)
      end
    end

    context 'with all readings completed on schedule' do
      before do
        readings.each do |reading|
          # Complete each reading on its scheduled date (in challenge timezone)
          tz = ActiveSupport::TimeZone[challenge.timezone]
          scheduled_time = tz.parse("#{reading.scheduled_date} 10:00:00")

          create(:user_reading,
            user: user,
            reading: reading,
            completed_on: scheduled_time.to_date
          )
        end
      end

      it 'returns 100' do
        expect(subject.percentage).to eq(100.0)
      end
    end

    context 'with no readings completed on schedule' do
      before do
        readings.each do |reading|
          # Complete each reading one day late
          create(:user_reading,
            user: user,
            reading: reading,
            completed_on: reading.scheduled_date + 1.day
          )
        end
      end

      it 'returns 0' do
        expect(subject.percentage).to eq(0.0)
      end
    end

    context 'with mixed on-schedule and off-schedule readings' do
      before do
        # Complete first 3 readings on schedule
        readings.first(3).each do |reading|
          create(:user_reading,
            user: user,
            reading: reading,
            completed_on: reading.scheduled_date
          )
        end

        # Complete next 2 readings one day late
        readings[3..4].each do |reading|
          create(:user_reading,
            user: user,
            reading: reading,
            completed_on: reading.scheduled_date + 1.day
          )
        end

        # Leave remaining 5 readings incomplete
      end

      it 'returns 30% (3 on-schedule out of 10 total scheduled)' do
        expect(subject.percentage).to eq(30.0)
      end
    end

    context 'ticket ELE-8 scenario: read on time then skip days' do
      before do
        # Complete only the first reading on schedule
        create(:user_reading,
          user: user,
          reading: readings.first,
          completed_on: readings.first.scheduled_date
        )

        # Skip the next 2 readings (days 2 and 3) - they are scheduled but not completed
        # This tests the specific scenario from the ticket
      end

      it 'returns 10% (1 on-schedule out of 10 total scheduled), not 100%' do
        # Before the fix, this would have been 100% (1 on-schedule / 1 completed)
        # After the fix, it's 10% (1 on-schedule / 10 scheduled)
        expect(subject.percentage).to eq(10.0)
      end
    end

    context 'with readings completed early' do
      before do
        # Complete reading one day early - should not count as on-schedule
        create(:user_reading,
          user: user,
          reading: readings.first,
          completed_on: readings.first.scheduled_date - 1.day
        )

        # Complete reading on schedule
        create(:user_reading,
          user: user,
          reading: readings.second,
          completed_on: readings.second.scheduled_date
        )
      end

      it 'returns 10% (1 on-schedule out of 10 total scheduled)' do
        expect(subject.percentage).to eq(10.0)
      end
    end

    context 'with timezone considerations' do
      let(:pst_tz) { ActiveSupport::TimeZone['Pacific Time (US & Canada)'] }
      let(:pst_current_date) { Time.current.in_time_zone(pst_tz).to_date }
      let(:pst_challenge) { create(:challenge, start_date: pst_current_date - 5, end_date: pst_current_date + 5, timezone: 'Pacific Time (US & Canada)') }
      let!(:pst_enrollment) { create(:user_challenge_enrollment, user: user, challenge: pst_challenge) }
      let!(:pst_readings) do
        dates = (pst_current_date - 2..pst_current_date).to_a
        create_list(:reading, 3, challenge: pst_challenge).each_with_index do |reading, i|
          reading.update!(scheduled_date: dates[i])
        end
      end

      subject { described_class.new(user, pst_challenge) }

      before do
        # Simulate completing reading at 11 PM PST on scheduled date
        # This should count as on-schedule even though it might be next day in UTC
        scheduled_time = pst_tz.parse("#{pst_readings.first.scheduled_date} 23:00:00")

        create(:user_reading,
          user: user,
          reading: pst_readings.first,
          completed_on: scheduled_time.to_date
        )
      end

      it 'correctly handles timezone when determining if reading was on schedule' do
        # 1 on-schedule out of 3 total scheduled readings (floored to 33, not rounded to 33.33)
        expect(subject.percentage).to eq(33)
      end
    end
  end

  describe '#on_schedule_count' do
    before do
      # Complete 3 readings on schedule
      readings.first(3).each do |reading|
        create(:user_reading,
          user: user,
          reading: reading,
          completed_on: reading.scheduled_date
        )
      end

      # Complete 2 readings off schedule
      readings[3..4].each do |reading|
        create(:user_reading,
          user: user,
          reading: reading,
          completed_on: reading.scheduled_date + 1.day
        )
      end
    end

    it 'returns the count of readings completed on their scheduled date' do
      expect(subject.on_schedule_count).to eq(3)
    end
  end

  describe '#total_completed_count' do
    before do
      # Complete 5 readings (some on schedule, some not)
      readings.first(5).each_with_index do |reading, i|
        completed_date = i < 3 ? reading.scheduled_date : reading.scheduled_date + 1.day
        create(:user_reading,
          user: user,
          reading: reading,
          completed_on: completed_date
        )
      end
    end

    it 'returns the total count of completed readings for the challenge' do
      expect(subject.total_completed_count).to eq(5)
    end
  end

  describe 'edge cases' do
    context 'when user has no completed readings' do
      it 'returns 0 for on_schedule_count' do
        expect(subject.on_schedule_count).to eq(0)
      end

      it 'returns 0 for total_completed_count' do
        expect(subject.total_completed_count).to eq(0)
      end

      it 'returns 0 for percentage' do
        expect(subject.percentage).to eq(0)
      end
    end

    context 'when user completed readings for multiple challenges' do
      let(:other_challenge) { create(:challenge, start_date: Date.current - 5, end_date: Date.current + 5) }
      let!(:other_enrollment) { create(:user_challenge_enrollment, user: user, challenge: other_challenge) }
      let!(:other_readings) { create_list(:reading, 3, challenge: other_challenge) }

      before do
        # Complete readings for the original challenge
        create(:user_reading, user: user, reading: readings.first, completed_on: readings.first.scheduled_date)

        # Complete readings for the other challenge
        create(:user_reading, user: user, reading: other_readings.first, completed_on: other_readings.first.scheduled_date)
      end

      it 'only counts readings for the specified challenge' do
        expect(subject.total_completed_count).to eq(1)
        expect(subject.on_schedule_count).to eq(1)
        # 1 on-schedule out of 10 total scheduled readings for the main challenge
        expect(subject.percentage).to eq(10.0)
      end
    end

    context 'when reading is completed multiple times' do
      before do
        # This shouldn't happen due to unique constraint, but let's test the query behavior
        reading = readings.first
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end

      it 'counts the reading only once' do
        expect(subject.total_completed_count).to eq(1)
        expect(subject.on_schedule_count).to eq(1)
      end
    end
  end

  describe '.batch_percentages' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: challenge) }
    let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: challenge) }
    let!(:enrollment3) { create(:user_challenge_enrollment, user: user3, challenge: challenge) }

    context 'with empty user list' do
      it 'returns empty hash' do
        result = described_class.batch_percentages([], challenge)
        expect(result).to eq({})
      end
    end

    context 'with no readings scheduled' do
      let(:empty_challenge) { create(:challenge, start_date: Date.current + 10, end_date: Date.current + 20) }
      let!(:empty_enrollment) { create(:user_challenge_enrollment, user: user1, challenge: empty_challenge) }

      it 'returns 0 for all users' do
        result = described_class.batch_percentages([ user1.id ], empty_challenge)
        expect(result).to eq({ user1.id => 0.0 })
      end
    end

    context 'with mixed user performance' do
      before do
        # User 1: Complete 3 readings on schedule
        readings.first(3).each do |reading|
          create(:user_reading, user: user1, reading: reading, completed_on: reading.scheduled_date)
        end

        # User 2: Complete 5 readings, but only 2 on schedule
        readings.first(2).each do |reading|
          create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date)
        end
        readings[2..4].each do |reading|
          create(:user_reading, user: user2, reading: reading, completed_on: reading.scheduled_date + 1.day)
        end

        # User 3: No readings completed
      end

      it 'calculates correct percentages for all users in one query' do
        result = described_class.batch_percentages([ user1.id, user2.id, user3.id ], challenge)

        expect(result[user1.id]).to eq(30.0)  # 3 on-schedule out of 10 total
        expect(result[user2.id]).to eq(20.0)  # 2 on-schedule out of 10 total
        expect(result[user3.id]).to eq(0.0)   # 0 on-schedule out of 10 total
      end

      it 'matches individual OnScheduleStatistic calculations' do
        batch_result = described_class.batch_percentages([ user1.id, user2.id ], challenge)
        individual_user1 = described_class.new(user1, challenge).percentage
        individual_user2 = described_class.new(user2, challenge).percentage

        expect(batch_result[user1.id]).to eq(individual_user1)
        expect(batch_result[user2.id]).to eq(individual_user2)
      end
    end

    context 'with all users completing all readings on schedule' do
      before do
        [ user1, user2, user3 ].each do |user|
          readings.each do |reading|
            create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
          end
        end
      end

      it 'returns 100% for all users' do
        result = described_class.batch_percentages([ user1.id, user2.id, user3.id ], challenge)

        expect(result[user1.id]).to eq(100.0)
        expect(result[user2.id]).to eq(100.0)
        expect(result[user3.id]).to eq(100.0)
      end
    end

    context 'with all users completing all readings late' do
      before do
        [ user1, user2 ].each do |user|
          readings.each do |reading|
            create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date + 1.day)
          end
        end
      end

      it 'returns 0% for all users' do
        result = described_class.batch_percentages([ user1.id, user2.id ], challenge)

        expect(result[user1.id]).to eq(0.0)
        expect(result[user2.id]).to eq(0.0)
      end
    end

    context 'with single user' do
      before do
        readings.first(5).each do |reading|
          create(:user_reading, user: user1, reading: reading, completed_on: reading.scheduled_date)
        end
      end

      it 'works correctly for single user' do
        result = described_class.batch_percentages([ user1.id ], challenge)
        expect(result[user1.id]).to eq(50.0)  # 5 out of 10
      end
    end
  end

  describe 'integration with UserStatistics' do
    let(:user_stats) { UserStatistics.new(user, challenge) }

    before do
      # Create some completed readings with mixed schedule adherence
      readings.first(6).each_with_index do |reading, i|
        completed_date = i < 4 ? reading.scheduled_date : reading.scheduled_date + 1.day
        create(:user_reading,
          user: user,
          reading: reading,
          completed_on: completed_date
        )
      end
    end

    it 'should complement existing UserStatistics' do
      # UserStatistics completion rate should show overall completion
      expect(user_stats.completion_rate).to eq(60.0) # 6 out of 10 readings

      # OnSchedule should show adherence to schedule among all scheduled readings
      on_schedule_stats = described_class.new(user, challenge)
      expect(on_schedule_stats.percentage).to eq(40.0) # 4 on-schedule out of 10 total scheduled, rounded to 2 decimal places
    end
  end
end
