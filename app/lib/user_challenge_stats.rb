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

    completed = completed_readings_count
    return 100 if completed == total_readings

    (completed.to_f / total_readings * 100).floor
  end

  # Completion percentage relative to readings scheduled up to current date
  # If there are 100 readings across 100 days, we're on day 50, and user completed 25, returns 50.0
  def on_track_percentage
    return 0.0 if readings_to_date.zero?

    completed = completed_readings_to_date_count
    return 100 if completed >= readings_to_date

    (completed.to_f / readings_to_date * 100).floor
  end

  private

  def total_readings
    @total_readings ||= begin
      query = challenge.readings
      query = query.where("scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
      query = query.where("scheduled_date <= ?", challenge.stats_end_date) if challenge.stats_end_date.present?
      query.count
    end
  end

  def completed_readings_count
    @completed_readings_count ||= begin
      query = user.user_readings.joins(:reading).where(readings: { challenge_id: challenge.id })
      query = query.where("readings.scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
      query = query.where("readings.scheduled_date <= ?", challenge.stats_end_date) if challenge.stats_end_date.present?
      query.count
    end
  end

  def readings_to_date
    @readings_to_date ||= begin
      effective_today = current_date_in_challenge_timezone
      effective_end = challenge.stats_end_date.present? ? [ challenge.stats_end_date, effective_today ].min : effective_today
      if challenge.stats_start_date.present? && effective_end < challenge.stats_start_date
        0
      else
        query = challenge.readings.where("scheduled_date <= ?", effective_end)
        query = query.where("scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
        query.count
      end
    end
  end

  def completed_readings_to_date_count
    @completed_readings_to_date_count ||= begin
      effective_today = current_date_in_challenge_timezone
      effective_end = challenge.stats_end_date.present? ? [ challenge.stats_end_date, effective_today ].min : effective_today
      if challenge.stats_start_date.present? && effective_end < challenge.stats_start_date
        0
      else
        query = user.user_readings.joins(:reading).where(readings: { challenge_id: challenge.id })
        query = query.where("readings.scheduled_date <= ?", effective_end)
        query = query.where("readings.scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
        query.count
      end
    end
  end

  def current_date_in_challenge_timezone
    Time.current.in_time_zone(challenge.timezone).to_date
  end
end
