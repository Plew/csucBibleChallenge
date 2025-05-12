# frozen_string_literal: true

require 'rails_helper'

describe ChallengeStatistics do
  let(:challenge) { create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10) }
  let(:users) { create_list(:user, 3) }
  let!(:enrollments) { users.map { |user| create(:user_challenge_enrollment, user: user, challenge: challenge) } }
  let!(:readings) do
    dates = (Date.current - 4..Date.current).to_a
    create_list(:reading, 5, challenge: challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
  end

  subject { described_class.new(challenge) }

  describe '#total_chapters_read' do
    it 'returns 0 if no readings completed' do
      expect(subject.total_chapters_read).to eq(0)
    end

    it 'returns the total number of chapters read by all users' do
      users.each { |user| create(:user_reading, user: user, reading: readings.first, completed_on: readings.first.scheduled_date) }
      expect(subject.total_chapters_read).to eq(3)
    end
  end

  describe '#number_of_participants' do
    it 'returns the number of users enrolled in the challenge' do
      expect(subject.number_of_participants).to eq(3)
    end
  end

  describe '#top_participants_by_completion' do
    it 'returns users sorted by completion rate' do
      # User 0 completes all, user 1 completes 2, user 2 completes 1
      readings.each { |reading| create(:user_reading, user: users[0], reading: reading, completed_on: reading.scheduled_date) }
      readings.first(2).each { |reading| create(:user_reading, user: users[1], reading: reading, completed_on: reading.scheduled_date) }
      create(:user_reading, user: users[2], reading: readings.first, completed_on: readings.first.scheduled_date)
      result = subject.top_participants_by_completion(3)
      expect(result.map(&:first)).to eq([users[0], users[1], users[2]])
    end
  end

  describe '#top_participants_by_streak' do
    it 'returns users sorted by longest streak' do
      # User 0: streak 5, user 1: streak 2, user 2: streak 1
      readings.each { |reading| create(:user_reading, user: users[0], reading: reading, completed_on: reading.scheduled_date) }
      readings.first(2).each { |reading| create(:user_reading, user: users[1], reading: reading, completed_on: reading.scheduled_date) }
      create(:user_reading, user: users[2], reading: readings.first, completed_on: readings.first.scheduled_date)
      result = subject.top_participants_by_streak(3)
      expect(result.map(&:first)).to eq([users[0], users[1], users[2]])
    end
  end
end 