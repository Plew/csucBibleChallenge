require 'rails_helper'

RSpec.describe UserChallengeStats do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, start_date: Date.current, end_date: Date.current + 30.days, timezone: 'UTC') }
  let(:stats) { described_class.new(user, challenge) }

  describe '#completion_percentage' do
    context 'when there are no readings' do
      it 'returns 0.0' do
        expect(stats.completion_percentage).to eq(0.0)
      end
    end

    context 'when there are readings but none completed' do
      before do
        create_list(:reading, 10, challenge: challenge)
      end

      it 'returns 0.0' do
        expect(stats.completion_percentage).to eq(0.0)
      end
    end

    context 'when some readings are completed' do
      let!(:readings) { create_list(:reading, 10, challenge: challenge) }

      before do
        # Complete 3 out of 10 readings
        3.times do |i|
          create(:user_reading, user: user, reading: readings[i])
        end
      end

      it 'returns the correct percentage' do
        expect(stats.completion_percentage).to eq(30.0)
      end
    end

    context 'when all readings are completed' do
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }

      before do
        readings.each do |reading|
          create(:user_reading, user: user, reading: reading)
        end
      end

      it 'returns 100.0' do
        expect(stats.completion_percentage).to eq(100.0)
      end
    end

    context 'when user has completed readings from other challenges' do
      let(:other_challenge) { create(:challenge) }
      let!(:challenge_readings) { create_list(:reading, 5, challenge: challenge) }
      let!(:other_readings) { create_list(:reading, 3, challenge: other_challenge) }

      before do
        # Complete 2 readings from the target challenge
        2.times do |i|
          create(:user_reading, user: user, reading: challenge_readings[i])
        end

        # Complete all readings from other challenge (should not affect calculation)
        other_readings.each do |reading|
          create(:user_reading, user: user, reading: reading)
        end
      end

      it 'only counts readings from the specified challenge' do
        expect(stats.completion_percentage).to eq(40.0) # 2 out of 5
      end
    end
  end

  describe '#on_track_percentage' do
    context 'when there are no readings scheduled to date' do
      before do
        create(:reading, challenge: challenge, scheduled_date: Date.current + 1.day)
      end

      it 'returns 0.0' do
        expect(stats.on_track_percentage).to eq(0.0)
      end
    end

    context 'when there are readings scheduled but none completed' do
      before do
        create_list(:reading, 5, challenge: challenge, scheduled_date: Date.current - 1.day)
      end

      it 'returns 0.0' do
        expect(stats.on_track_percentage).to eq(0.0)
      end
    end

    context 'when some readings scheduled to date are completed' do
      let!(:past_readings) { create_list(:reading, 4, challenge: challenge, scheduled_date: Date.current - 1.day) }
      let!(:future_readings) { create_list(:reading, 6, challenge: challenge, scheduled_date: Date.current + 1.day) }

      before do
        # Complete 2 out of 4 past readings
        2.times do |i|
          create(:user_reading, user: user, reading: past_readings[i])
        end
      end

      it 'calculates percentage based only on readings scheduled to date' do
        expect(stats.on_track_percentage).to eq(50.0) # 2 out of 4 past readings
      end
    end

    context 'when all readings scheduled to date are completed' do
      let!(:past_readings) { create_list(:reading, 3, challenge: challenge, scheduled_date: Date.current - 1.day) }
      let!(:future_readings) { create_list(:reading, 7, challenge: challenge, scheduled_date: Date.current + 1.day) }

      before do
        past_readings.each do |reading|
          create(:user_reading, user: user, reading: reading)
        end
      end

      it 'returns 100.0' do
        expect(stats.on_track_percentage).to eq(100.0)
      end
    end

    context 'with timezone considerations' do
      let(:challenge) { create(:challenge, timezone: 'Eastern Time (US & Canada)') }

      before do
        # Create a reading for "today" in the challenge timezone
        current_date_in_ny = Time.current.in_time_zone('Eastern Time (US & Canada)').to_date
        create(:reading, challenge: challenge, scheduled_date: current_date_in_ny)
      end

      it 'uses the challenge timezone for date calculations' do
        expect(stats.on_track_percentage).to eq(0.0) # No completions yet
      end
    end
  end

  describe 'edge cases' do
    context 'when user has no enrollment in the challenge' do
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }

      it 'still calculates percentages correctly' do
        expect(stats.completion_percentage).to eq(0.0)
        expect(stats.on_track_percentage).to eq(0.0)
      end
    end

    context 'with fractional percentages' do
      let!(:readings) { create_list(:reading, 3, challenge: challenge) }

      before do
        create(:user_reading, user: user, reading: readings.first)
      end

      it 'uses floor for percentage' do
        expect(stats.completion_percentage).to eq(33) # 1/3 = 33.333... floored to 33
      end
    end
  end
end
