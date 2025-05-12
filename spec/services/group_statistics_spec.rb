# frozen_string_literal: true

require 'rails_helper'

describe GroupStatistics do
  let(:challenge) { create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10) }
  let(:group) { create(:group, challenge: challenge) }
  let(:users) { create_list(:user, 3) }
  let!(:enrollments) do
    users.map { |user| create(:user_challenge_enrollment, user: user, challenge: challenge, group: group) }
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
      expect(subject.last_membership_change_date).to eq(enrollments.map(&:updated_at).max.to_date)
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

    it 'returns 33.33 if one of three completed the reading' do
      create(:user_reading, user: users.first, reading: readings.first, completed_on: readings.first.scheduled_date)
      stat = described_class.new(group)
      expect(stat.check_in_percentage(readings.first.scheduled_date)).to be_within(0.01).of(33.33)
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
end 