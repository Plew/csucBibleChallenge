# frozen_string_literal: true

class UserStatistics
  attr_reader :user, :challenge

  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  # Percentage of readings completed by the user up to the current date
  def completion_rate
    total_readings = challenge.readings.where('scheduled_date <= ?', Date.current).count
    return 0 if total_readings.zero?
    completed = user.user_readings.joins(:reading).where(readings: { challenge_id: challenge.id }).where('readings.scheduled_date <= ?', Date.current).count
    (completed.to_f / total_readings * 100).round(2)
  end

  # Longest streak of consecutive days with completed readings
  def longest_streak
    dates = user.user_readings.joins(:reading).where(readings: { challenge_id: challenge.id }).pluck(:completed_on).uniq.sort
    max_streak = 0
    current_streak = 0
    prev_date = nil
    dates.each do |date|
      if prev_date && date == prev_date + 1.day
        current_streak += 1
      else
        current_streak = 1
      end
      max_streak = [max_streak, current_streak].max
      prev_date = date
    end
    max_streak
  end

  def join_date
    user.user_challenge_enrollments.find_by(challenge: challenge)&.created_at&.to_date
  end

  def days_since_last_activity
    last = last_activity_date
    last ? (Date.current - last).to_i : nil
  end

  def last_check_in_date
    user.user_readings.joins(:reading).where(readings: { challenge_id: challenge.id }).maximum(:completed_on)
  end

  def last_login_date
    user.last_login_at&.to_date if user.respond_to?(:last_login_at)
  end

  private

  def last_activity_date
    [last_check_in_date, last_login_date].compact.max
  end
end 