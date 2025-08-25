# frozen_string_literal: true

require 'rails_helper'

describe OnScheduleStatistic do
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

      it 'returns 60% (3 on-schedule out of 5 total completed)' do
        expect(subject.percentage).to eq(60.0)
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

      it 'returns 50% (1 on-schedule out of 2 total completed)' do
        expect(subject.percentage).to eq(50.0)
      end
    end

    context 'with timezone considerations' do
      let(:pst_challenge) { create(:challenge, start_date: Date.current - 5, end_date: Date.current + 5, timezone: 'Pacific Time (US & Canada)') }
      let!(:pst_enrollment) { create(:user_challenge_enrollment, user: user, challenge: pst_challenge) }
      let!(:pst_readings) do
        dates = (Date.current - 2..Date.current).to_a
        create_list(:reading, 3, challenge: pst_challenge).each_with_index do |reading, i|
          reading.update!(scheduled_date: dates[i])
        end
      end

      subject { described_class.new(user, pst_challenge) }

      before do
        # Simulate completing reading at 11 PM PST on scheduled date
        # This should count as on-schedule even though it might be next day in UTC
        pst_tz = ActiveSupport::TimeZone['Pacific Time (US & Canada)']
        scheduled_time = pst_tz.parse("#{pst_readings.first.scheduled_date} 23:00:00")

        create(:user_reading,
          user: user,
          reading: pst_readings.first,
          completed_on: scheduled_time.to_date
        )
      end

      it 'correctly handles timezone when determining if reading was on schedule' do
        expect(subject.percentage).to eq(100.0)
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
        expect(subject.percentage).to eq(100.0)
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

      # OnSchedule should show adherence to schedule among completed
      on_schedule_stats = described_class.new(user, challenge)
      expect(on_schedule_stats.percentage).to eq(66.67) # 4 on-schedule out of 6 completed, rounded to 2 decimal places
    end
  end
end
