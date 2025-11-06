# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserStatistics, type: :service do
  let(:challenge) { create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10) }
  let(:user) { create(:user) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge, created_at: Date.current - 5) }
  let!(:readings) do
    dates = (Date.current - 9..Date.current).to_a
    create_list(:reading, 10, challenge: challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
  end

  subject { described_class.new(user, challenge) }

  describe '#completion_rate' do
    it 'returns 0 if no readings completed' do
      expect(subject.completion_rate).to eq(0)
    end

    it 'returns 100 if all readings completed' do
      readings.each do |reading|
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end
      expect(subject.completion_rate).to eq(100)
    end

    it 'returns 50 if half readings completed' do
      readings.first(5).each do |reading|
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end
      expect(subject.completion_rate).to eq(50)
    end
  end

  describe '#longest_streak' do
    it 'returns 0 if no readings completed' do
      expect(subject.longest_streak).to eq(0)
    end

    it 'returns correct streak for consecutive completions' do
      readings.first(3).each do |reading|
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end
      expect(subject.longest_streak).to eq(3)
    end

    it 'returns correct streak with gaps' do
      create(:user_reading, user: user, reading: readings[0], completed_on: readings[0].scheduled_date)
      create(:user_reading, user: user, reading: readings[2], completed_on: readings[2].scheduled_date)
      create(:user_reading, user: user, reading: readings[3], completed_on: readings[3].scheduled_date)
      expect(subject.longest_streak).to eq(2)
    end
  end

  describe '#join_date' do
    it 'returns the enrollment created_at date' do
      expect(subject.join_date).to eq(enrollment.created_at.to_date)
    end
  end

  describe '#days_since_last_activity' do
    it 'returns nil if no activity' do
      expect(subject.days_since_last_activity).to be_nil
    end

    it 'returns correct days since last activity' do
      create(:user_reading, user: user, reading: readings.last, completed_on: Date.current - 2)
      expect(subject.days_since_last_activity).to eq(2)
    end
  end

  describe '#last_check_in_date' do
    it 'returns nil if no check-ins' do
      expect(subject.last_check_in_date).to be_nil
    end

    it 'returns the most recent check-in date' do
      create(:user_reading, user: user, reading: readings.last, completed_on: Date.current - 1)
      expect(subject.last_check_in_date).to eq(Date.current - 1)
    end
  end

  describe '#on_schedule_percentage' do
    it 'returns 0 if no readings completed' do
      expect(subject.on_schedule_percentage).to eq(0)
    end

    it 'returns 30% if 3 out of 10 scheduled readings were completed on schedule' do
      readings.first(3).each do |reading|
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end
      # 3 on-schedule out of 10 total scheduled = 30%
      expect(subject.on_schedule_percentage).to eq(30.0)
    end

    it 'returns correct percentage for mixed on/off schedule readings' do
      # Complete 4 readings: 3 on schedule, 1 off schedule
      readings.first(3).each do |reading|
        create(:user_reading, user: user, reading: reading, completed_on: reading.scheduled_date)
      end
      create(:user_reading, user: user, reading: readings[3], completed_on: readings[3].scheduled_date + 1.day)

      # 3 on-schedule out of 10 total scheduled = 30%
      expect(subject.on_schedule_percentage).to eq(30.0)
    end
  end
end
