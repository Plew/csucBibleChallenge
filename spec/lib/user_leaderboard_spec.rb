require 'rails_helper'

RSpec.describe UserLeaderboard do
  let(:challenge) { create(:challenge, start_date: Date.current - 10.days, end_date: Date.current + 20.days, timezone: 'UTC') }
  let(:leaderboard) { described_class.new(challenge, limit: 5) }

  # Create users and enroll them in the challenge
  let!(:user1) { create(:user, username: 'alice') }
  let!(:user2) { create(:user, username: 'bob') }
  let!(:user3) { create(:user, username: 'charlie') }
  let!(:user4) { create(:user, username: 'diana') }

  before do
    # Enroll all users in the challenge
    [ user1, user2, user3, user4 ].each do |user|
      create(:user_challenge_enrollment, user: user, challenge: challenge)
    end
  end

  describe '#by_completion_percentage' do
    context 'when challenge has no readings' do
      it 'returns empty array' do
        expect(leaderboard.by_completion_percentage).to eq([])
      end
    end

    context 'when challenge has readings but no completions' do
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }

      it 'returns users ordered by username with 0% completion' do
        results = leaderboard.by_completion_percentage
        expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie', 'diana' ])
        results.each { |user| expect(user.completion_percentage).to eq(0.0) }
      end
    end

    context 'when users have different completion rates' do
      let!(:readings) { create_list(:reading, 10, challenge: challenge) }

      before do
        # user1: 8/10 = 80%
        8.times { |i| create(:user_reading, user: user1, reading: readings[i]) }

        # user2: 6/10 = 60%
        6.times { |i| create(:user_reading, user: user2, reading: readings[i]) }

        # user3: 6/10 = 60% (same as user2, should be ordered by username)
        6.times { |i| create(:user_reading, user: user3, reading: readings[i]) }

        # user4: 2/10 = 20%
        2.times { |i| create(:user_reading, user: user4, reading: readings[i]) }
      end

      it 'returns users ordered by completion percentage descending, then username ascending' do
        results = leaderboard.by_completion_percentage
        expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie', 'diana' ])
        expect(results.map(&:completion_percentage)).to eq([ 80.0, 60.0, 60.0, 20.0 ])
        expect(results.map(&:completed_count)).to eq([ 8, 6, 6, 2 ])
      end
    end

    context 'with limit parameter' do
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }
      let(:limited_leaderboard) { described_class.new(challenge, limit: 2) }

      before do
        4.times { |i| create(:user_reading, user: user1, reading: readings[i]) }
        3.times { |i| create(:user_reading, user: user2, reading: readings[i]) }
        2.times { |i| create(:user_reading, user: user3, reading: readings[i]) }
        1.times { |i| create(:user_reading, user: user4, reading: readings[i]) }
      end

      it 'respects the limit parameter' do
        results = limited_leaderboard.by_completion_percentage
        expect(results.length).to eq(2)
        expect(results.map(&:username)).to eq([ 'alice', 'bob' ])
      end
    end

    context 'when users have completions from other challenges' do
      let(:other_challenge) { create(:challenge) }
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }
      let!(:other_readings) { create_list(:reading, 3, challenge: other_challenge) }

      before do
        # Complete readings from target challenge
        2.times { |i| create(:user_reading, user: user1, reading: readings[i]) }

        # Complete readings from other challenge (should not affect ranking)
        other_readings.each { |reading| create(:user_reading, user: user1, reading: reading) }
        other_readings.each { |reading| create(:user_reading, user: user2, reading: reading) }
      end

      it 'only counts readings from the specified challenge' do
        results = leaderboard.by_completion_percentage

        # All enrolled users should appear in results
        expect(results.length).to eq(4)
        expect(results.map(&:username).sort).to eq([ 'alice', 'bob', 'charlie', 'diana' ])

        alice = results.find { |u| u.username == 'alice' }
        bob = results.find { |u| u.username == 'bob' }

        expect(alice.completion_percentage).to eq(40.0) # 2/5 from target challenge
        expect(bob.completion_percentage).to eq(0.0) # 0/5 from target challenge (other challenge completions don't count)
      end
    end
  end

  describe '#by_on_track_percentage' do
    context 'when there are no readings scheduled to date' do
      before do
        create(:reading, challenge: challenge, scheduled_date: Date.current + 1.day)
      end

      it 'returns empty array' do
        expect(leaderboard.by_on_track_percentage).to eq([])
      end
    end

    context 'when there are readings scheduled to date' do
      let!(:past_readings) { create_list(:reading, 4, challenge: challenge, scheduled_date: Date.current - 1.day) }
      let!(:future_readings) { create_list(:reading, 6, challenge: challenge, scheduled_date: Date.current + 1.day) }

      before do
        # user1: 3/4 past readings = 75%
        3.times { |i| create(:user_reading, user: user1, reading: past_readings[i]) }

        # user2: 2/4 past readings = 50%
        2.times { |i| create(:user_reading, user: user2, reading: past_readings[i]) }

        # user3: 2/4 past readings = 50% (same as user2)
        2.times { |i| create(:user_reading, user: user3, reading: past_readings[i]) }

        # user4: 1/4 past readings = 25%
        create(:user_reading, user: user4, reading: past_readings[0])
      end

      it 'calculates on-track percentage based only on readings scheduled to date' do
        results = leaderboard.by_on_track_percentage
        expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie', 'diana' ])
        expect(results.map(&:on_track_percentage)).to eq([ 75.0, 50.0, 50.0, 25.0 ])
        expect(results.map(&:completed_to_date_count)).to eq([ 3, 2, 2, 1 ])
      end
    end

    context 'with timezone considerations' do
      let(:challenge) { create(:challenge, timezone: 'Eastern Time (US & Canada)') }

      before do
        current_date_et = Time.current.in_time_zone('Eastern Time (US & Canada)').to_date
        create(:reading, challenge: challenge, scheduled_date: current_date_et)
      end

      it 'uses challenge timezone for date calculations' do
        results = leaderboard.by_on_track_percentage
        expect(results.map(&:on_track_percentage)).to all(eq(0.0))
      end
    end
  end

  describe '#by_total_readings' do
    let!(:readings) { create_list(:reading, 5, challenge: challenge) }

    before do
      # user1: 4 completions
      4.times { |i| create(:user_reading, user: user1, reading: readings[i]) }

      # user2: 3 completions
      3.times { |i| create(:user_reading, user: user2, reading: readings[i]) }

      # user3: 3 completions (same as user2)
      3.times { |i| create(:user_reading, user: user3, reading: readings[i]) }

      # user4: 1 completion
      create(:user_reading, user: user4, reading: readings[0])
    end

    it 'returns users ordered by total reading count descending, then username ascending' do
      results = leaderboard.by_total_readings
      expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie', 'diana' ])
      expect(results.map(&:total_completed)).to eq([ 4, 3, 3, 1 ])
    end
  end

  describe '#by_current_streak' do
    let!(:readings) do
      # Create readings for consecutive days
      (0..5).map do |days_ago|
        create(:reading, challenge: challenge, scheduled_date: Date.current - days_ago.days)
      end
    end

    context 'when users have different streak lengths' do
      before do
        # user1: 3-day streak (today, yesterday, day before)
        3.times { |i| create(:user_reading, user: user1, reading: readings[i]) }

        # user2: 2-day streak (today, yesterday)
        2.times { |i| create(:user_reading, user: user2, reading: readings[i]) }

        # user3: 1-day streak (today only)
        create(:user_reading, user: user3, reading: readings[0])

        # user4: no current streak (completed reading 3 days ago but missed yesterday and today)
        create(:user_reading, user: user4, reading: readings[3])
      end

      it 'returns users ordered by current streak length descending' do
        results = leaderboard.by_current_streak
        expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie', 'diana' ])
        expect(results.map(&:current_streak)).to eq([ 3, 2, 1, 0 ])
      end
    end

    context 'when users have no readings' do
      it 'returns users with 0 streak' do
        results = leaderboard.by_current_streak
        expect(results.map(&:current_streak)).to all(eq(0))
      end
    end
  end

  describe '#by_recent_activity' do
    let!(:readings) { create_list(:reading, 5, challenge: challenge) }

    before do
      # user1: most recent completion
      create(:user_reading, user: user1, reading: readings[0], completed_on: Date.current)

      # user2: completed yesterday
      create(:user_reading, user: user2, reading: readings[1], completed_on: Date.current - 1.day)

      # user3: completed 2 days ago
      create(:user_reading, user: user3, reading: readings[2], completed_on: Date.current - 2.days)

      # user4: no completions (will not appear in results)
    end

    it 'returns users ordered by most recent activity' do
      results = leaderboard.by_recent_activity
      expect(results.map(&:username)).to eq([ 'alice', 'bob', 'charlie' ])
      expect(results.map(&:last_reading_date).map(&:to_date)).to eq([
        Date.current,
        Date.current - 1.day,
        Date.current - 2.days
      ])
    end

    it 'does not include users with no completions' do
      results = leaderboard.by_recent_activity
      expect(results.map(&:username)).not_to include('diana')
    end
  end

  describe 'edge cases' do
    context 'when challenge has no enrolled users' do
      let(:empty_challenge) { create(:challenge) }
      let(:empty_leaderboard) { described_class.new(empty_challenge) }

      it 'returns empty arrays for all leaderboard types' do
        expect(empty_leaderboard.by_completion_percentage).to eq([])
        expect(empty_leaderboard.by_on_track_percentage).to eq([])
        expect(empty_leaderboard.by_total_readings).to eq([])
        expect(empty_leaderboard.by_current_streak).to eq([])
        expect(empty_leaderboard.by_recent_activity).to eq([])
      end
    end

    context 'with limit of 0' do
      let(:zero_limit_leaderboard) { described_class.new(challenge, limit: 0) }
      let!(:readings) { create_list(:reading, 5, challenge: challenge) }

      it 'returns empty arrays' do
        expect(zero_limit_leaderboard.by_completion_percentage).to eq([])
        expect(zero_limit_leaderboard.by_total_readings).to eq([])
        expect(zero_limit_leaderboard.by_current_streak.length).to eq(0)
      end
    end

    context 'with very large limit' do
      let(:large_limit_leaderboard) { described_class.new(challenge, limit: 1000) }
      let!(:readings) { create_list(:reading, 3, challenge: challenge) }

      it 'returns all available users' do
        results = large_limit_leaderboard.by_completion_percentage
        expect(results.length).to eq(4) # All enrolled users
      end
    end
  end

  describe 'performance considerations' do
    context 'with many users and readings' do
      let!(:many_users) { create_list(:user, 20) }
      let!(:many_readings) { create_list(:reading, 50, challenge: challenge) }

      before do
        many_users.each { |user| create(:user_challenge_enrollment, user: user, challenge: challenge) }

        # Add some completions
        many_users.first(10).each_with_index do |user, index|
          (index + 1).times { |i| create(:user_reading, user: user, reading: many_readings[i]) }
        end
      end

      it 'handles larger datasets efficiently' do
        expect { leaderboard.by_completion_percentage }.not_to raise_error
        expect { leaderboard.by_on_track_percentage }.not_to raise_error
        expect { leaderboard.by_total_readings }.not_to raise_error

        results = leaderboard.by_completion_percentage
        expect(results.length).to eq(5) # Respects limit
      end
    end
  end
end
