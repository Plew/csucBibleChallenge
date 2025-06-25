require 'rails_helper'

RSpec.describe GroupChallengeStats do
  let(:challenge) { create(:challenge, start_date: Date.current, end_date: Date.current + 30.days, timezone: 'UTC') }
  let(:group) { create(:group, challenge: challenge) }
  let(:stats) { described_class.new(group, challenge) }

  describe '#completion_percentage' do
    context 'when group has no members' do
      it 'returns 0.0' do
        expect(stats.completion_percentage).to eq(0.0)
      end
    end

    context 'when group has members but no readings' do
      let!(:users) { create_list(:user, 3) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
      end

      it 'returns 0.0' do
        expect(stats.completion_percentage).to eq(0.0)
      end
    end

    context 'when group has members and readings but no completions' do
      let!(:users) { create_list(:user, 3) }
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
      end

      it 'returns 0.0' do
        expect(stats.completion_percentage).to eq(0.0)
      end
    end

    context 'when some members have completed some readings' do
      let!(:users) { create_list(:user, 3) }
      let!(:readings) { create_list(:reading, 4, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # User 1 completes 2 readings
        2.times { |i| create(:user_reading, user: users[0], reading: readings[i]) }
        
        # User 2 completes 1 reading
        create(:user_reading, user: users[1], reading: readings[0])
        
        # User 3 completes 0 readings
        # Total: 3 completions out of 12 possible (3 users × 4 readings)
      end

      it 'calculates the correct group completion percentage' do
        expect(stats.completion_percentage).to eq(25.0) # 3/12 = 25%
      end
    end

    context 'when all members have completed all readings' do
      let!(:users) { create_list(:user, 2) }
      let!(:readings) { create_list(:reading, 3, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        users.each do |user|
          readings.each do |reading|
            create(:user_reading, user: user, reading: reading)
          end
        end
      end

      it 'returns 100.0' do
        expect(stats.completion_percentage).to eq(100.0)
      end
    end

    context 'when users have completions from other challenges' do
      let(:other_challenge) { create(:challenge) }
      let!(:users) { create_list(:user, 2) }
      let!(:challenge_readings) { create_list(:reading, 3, challenge: challenge) }
      let!(:other_readings) { create_list(:reading, 2, challenge: other_challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # Complete 1 reading from target challenge for user 1
        create(:user_reading, user: users[0], reading: challenge_readings[0])
        
        # Complete all readings from other challenge for both users (should not affect calculation)
        users.each do |user|
          other_readings.each do |reading|
            create(:user_reading, user: user, reading: reading)
          end
        end
      end

      it 'only counts readings from the specified challenge' do
        expect(stats.completion_percentage).to eq(16.7) # 1 out of 6 possible (2 users × 3 readings)
      end
    end

    context 'when users are in multiple groups' do
      let(:other_group) { create(:group, challenge: challenge) }
      let!(:users) { create_list(:user, 2) }
      let!(:other_user) { create(:user) }
      let!(:readings) { create_list(:reading, 2, challenge: challenge) }
      
      before do
        # Add users to both groups
        users.each do |user|
          create(:user_group_enrollment, user: user, group: group)
          create(:user_group_enrollment, user: user, group: other_group)
        end
        
        # Add other_user only to other_group
        create(:user_group_enrollment, user: other_user, group: other_group)
        
        # Complete readings
        users.each { |user| create(:user_reading, user: user, reading: readings[0]) }
        create(:user_reading, user: other_user, reading: readings[0])
      end

      it 'only counts completions for members of the specified group' do
        expect(stats.completion_percentage).to eq(50.0) # 2 out of 4 possible (2 users × 2 readings)
      end
    end
  end

  describe '#on_track_percentage' do
    context 'when there are no readings scheduled to date' do
      let!(:users) { create_list(:user, 2) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        create(:reading, challenge: challenge, scheduled_date: Date.current + 1.day)
      end

      it 'returns 0.0' do
        expect(stats.on_track_percentage).to eq(0.0)
      end
    end

    context 'when there are readings scheduled but none completed' do
      let!(:users) { create_list(:user, 2) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        create_list(:reading, 3, challenge: challenge, scheduled_date: Date.current - 1.day)
      end

      it 'returns 0.0' do
        expect(stats.on_track_percentage).to eq(0.0)
      end
    end

    context 'when some readings scheduled to date are completed' do
      let!(:users) { create_list(:user, 2) }
      let!(:past_readings) { create_list(:reading, 3, challenge: challenge, scheduled_date: Date.current - 1.day) }
      let!(:future_readings) { create_list(:reading, 2, challenge: challenge, scheduled_date: Date.current + 1.day) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # Complete 2 past readings for user 1, 1 past reading for user 2
        2.times { |i| create(:user_reading, user: users[0], reading: past_readings[i]) }
        create(:user_reading, user: users[1], reading: past_readings[0])
        
        # Total: 3 completions out of 6 possible (2 users × 3 past readings)
      end

      it 'calculates percentage based only on readings scheduled to date' do
        expect(stats.on_track_percentage).to eq(50.0) # 3 out of 6 past readings
      end
    end

    context 'when all readings scheduled to date are completed' do
      let!(:users) { create_list(:user, 2) }
      let!(:past_readings) { create_list(:reading, 2, challenge: challenge, scheduled_date: Date.current - 1.day) }
      let!(:future_readings) { create_list(:reading, 3, challenge: challenge, scheduled_date: Date.current + 1.day) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        users.each do |user|
          past_readings.each do |reading|
            create(:user_reading, user: user, reading: reading)
          end
        end
      end

      it 'returns 100.0' do
        expect(stats.on_track_percentage).to eq(100.0)
      end
    end

    context 'with timezone considerations' do
      let(:challenge) { create(:challenge, timezone: 'Eastern Time (US & Canada)') }
      let!(:users) { create_list(:user, 2) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # Create a reading for "today" in the challenge timezone
        current_date_et = Time.current.in_time_zone('Eastern Time (US & Canada)').to_date
        create(:reading, challenge: challenge, scheduled_date: current_date_et)
      end

      it 'uses the challenge timezone for date calculations' do
        expect(stats.on_track_percentage).to eq(0.0) # No completions yet
      end
    end
  end

  describe 'edge cases' do
    context 'with fractional percentages' do
      let!(:users) { create_list(:user, 3) }
      let!(:readings) { create_list(:reading, 2, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # Complete 1 reading for 1 user = 1 out of 6 possible
        create(:user_reading, user: users[0], reading: readings[0])
      end

      it 'rounds to one decimal place' do
        expect(stats.completion_percentage).to eq(16.7) # 1/6 = 16.666...
      end
    end

    context 'when group belongs to different challenge than readings' do
      let(:different_challenge) { create(:challenge) }
      let(:different_group) { create(:group, challenge: different_challenge) }
      let(:different_stats) { described_class.new(different_group, challenge) }
      let!(:users) { create_list(:user, 2) }
      let!(:readings) { create_list(:reading, 2, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: different_group) }
        users.each { |user| create(:user_reading, user: user, reading: readings[0]) }
      end

      it 'handles cross-challenge scenarios correctly' do
        expect(different_stats.completion_percentage).to eq(50.0) # 2 out of 4 possible
      end
    end
  end

  describe 'performance considerations' do
    context 'with many group members and readings' do
      let!(:users) { create_list(:user, 10) }
      let!(:readings) { create_list(:reading, 20, challenge: challenge) }
      
      before do
        users.each { |user| create(:user_group_enrollment, user: user, group: group) }
        
        # Complete some readings
        users.first(5).each do |user|
          readings.first(10).each do |reading|
            create(:user_reading, user: user, reading: reading)
          end
        end
      end

      it 'calculates stats efficiently with large datasets' do
        expect(stats.completion_percentage).to eq(25.0) # 50 out of 200 possible
      end
    end
  end
end