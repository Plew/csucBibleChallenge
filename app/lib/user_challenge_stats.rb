class UserChallengeStats
  attr_reader :user, :challenge

  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  # Overall completion percentage across entire challenge
  # If there are 100 readings and user completed 25, returns 25.0
  def completion_percentage
    return 0.0 if total_readings.zero?

    (completed_readings_count.to_f / total_readings * 100).floor
  end

  # Completion percentage relative to readings scheduled up to current date
  # If there are 100 readings across 100 days, we're on day 50, and user completed 25, returns 50.0
  def on_track_percentage
    return 0.0 if readings_to_date.zero?

    (completed_readings_count.to_f / readings_to_date * 100).floor
  end

  private

  def total_readings
    @total_readings ||= challenge.readings.count
  end

  def completed_readings_count
    @completed_readings_count ||= user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .count
  end

  def readings_to_date
    @readings_to_date ||= challenge.readings
      .where("scheduled_date <= ?", current_date_in_challenge_timezone)
      .count
  end

  def current_date_in_challenge_timezone
    Time.current.in_time_zone(challenge.timezone).to_date
  end
end
