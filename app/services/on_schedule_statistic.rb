# frozen_string_literal: true

class OnScheduleStatistic
  attr_reader :user, :challenge

  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  # Percentage of completed readings that were completed on their scheduled date
  # Considers the challenge's timezone when determining if reading was "on schedule"
  def percentage
    return 0 if total_completed_count.zero?

    (on_schedule_count.to_f / total_completed_count * 100).round(2)
  end

  # Count of readings completed on their scheduled date
  def on_schedule_count
    user_readings_for_challenge
      .joins(:reading)
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .count
  end

  # Total count of completed readings for this challenge
  def total_completed_count
    user_readings_for_challenge.count
  end

  private

  def user_readings_for_challenge
    user.user_readings
        .joins(:reading)
        .where(readings: { challenge_id: challenge.id })
  end
end
