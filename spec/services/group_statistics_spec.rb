# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupStatistics, type: :service do
  let(:challenge) { create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10) }
  let(:group) { create(:group, challenge: challenge) }
  let(:users) { create_list(:user, 3) }
  let!(:setup_challenge_and_group_enrollments) do
    users.each do |user|
      create(:user_challenge_enrollment, user: user, challenge: challenge)
      create(:user_group_enrollment, user: user, group: group)
    end
  end
  let!(:readings) do
    dates = (Date.current - 4..Date.current).to_a
    create_list(:reading, 5, challenge: challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
  end

  subject { described_class.new(group) }

  describe '#group_size' do
    it 'returns the number of users in the group' do
      expect(subject.group_size).to eq(3)
    end
  end

  describe '#last_membership_change_date' do
    it 'returns the most recent updated_at of enrollments' do
      expect(subject.last_membership_change_date.to_date).to eq(group.user_group_enrollments.map(&:updated_at).map(&:to_date).max)
    end
  end

  describe '#check_in_percentage' do
    it 'returns 0 if no one completed the reading' do
      stat = described_class.new(group)
      expect(stat.check_in_percentage(readings.first.scheduled_date)).to eq(0)
    end

    it 'returns 100 if all completed the reading' do
      users.each { |user| create(:user_reading, user: user, reading: readings.first, completed_on: readings.first.scheduled_date) }
      stat = described_class.new(group)
      expect(stat.check_in_percentage(readings.first.scheduled_date)).to eq(100)
    end

    it 'returns 33 if one of three completed the reading (floored, not rounded)' do
      create(:user_reading, user: users.first, reading: readings.first, completed_on: readings.first.scheduled_date)
      stat = described_class.new(group)
      expect(stat.check_in_percentage(readings.first.scheduled_date)).to eq(33)
    end
  end

  describe '#longest_group_streak' do
    it 'returns 0 if no day all completed' do
      expect(subject.longest_group_streak).to eq(0)
    end

    it 'returns correct streak for consecutive days' do
      readings.each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      expect(subject.longest_group_streak).to eq(5)
    end

    it 'returns correct streak with a gap' do
      readings[0..1].each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      # skip day 2
      readings[3..4].each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      expect(subject.longest_group_streak).to eq(2)
    end
  end

  describe '#total_chapters_read' do
    it 'returns the total number of chapters read by the group' do
      users.each { |user| create(:user_reading, user: user, reading: readings.first, completed_on: readings.first.scheduled_date) }
      expect(subject.total_chapters_read).to eq(3)
    end
  end

  describe '#completion_percentage' do
    it 'returns 0 if no one completed any readings' do
      expect(subject.completion_percentage).to eq(0)
    end

    it 'returns 100 if all users completed all readings' do
      readings.each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      expect(subject.completion_percentage).to eq(100)
    end

    it 'returns 50 if all users completed half the readings' do
      readings.first(2).each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      expect(subject.completion_percentage).to eq(40)
    end
  end

  describe '#on_schedule_percentage' do
    it 'returns 0 if no one completed any readings' do
      expect(subject.on_schedule_percentage).to eq(0)
    end

    it 'returns 100 if all users completed all readings on schedule' do
      readings.each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end
      expect(subject.on_schedule_percentage).to eq(100)
    end

    it 'returns 0 if all users completed all readings late' do
      readings.each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date + 1.day) }
      end
      expect(subject.on_schedule_percentage).to eq(0)
    end

    it 'calculates average percentage across mixed user performance' do
      # User 1: 3 on-schedule out of 5 = 60%
      readings.first(3).each { |r| create(:user_reading, user: users[0], reading: r, completed_on: r.scheduled_date) }

      # User 2: 2 on-schedule out of 5 = 40%
      readings.first(2).each { |r| create(:user_reading, user: users[1], reading: r, completed_on: r.scheduled_date) }

      # User 3: 0 on-schedule out of 5 = 0%
      # (no readings)

      # Average: (60 + 40 + 0) / 3 = 33.33, rounded to 33
      expect(subject.on_schedule_percentage).to eq(33)
    end

    it 'returns 0 for empty group' do
      empty_group = create(:group, challenge: challenge)
      stat = described_class.new(empty_group)
      expect(stat.on_schedule_percentage).to eq(0)
    end

    it 'uses batch calculation (avoids N+1 queries)' do
      # Add some data
      readings.first(2).each do |reading|
        users.each { |user| create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date) }
      end

      # Expect batch_percentages to be called (not individual calculations)
      expect(OnScheduleStatistic).to receive(:batch_percentages).with(
        match_array(users.map(&:id)),
        challenge
      ).and_call_original

      subject.on_schedule_percentage
    end
  end
end
