class GroupChallengeStats
  attr_reader :group, :challenge

  def initialize(group, challenge)
    @group = group
    @challenge = challenge
  end

  # Overall completion percentage across entire challenge for all group members
  def completion_percentage
    total_possible = group.users.count * total_readings
    return 0.0 if total_possible.zero?

    completed = completed_readings_count
    return 100 if completed == total_possible

    (completed.to_f / total_possible * 100).floor
  end

  # Completion percentage relative to readings scheduled up to current date for all group members
  def on_track_percentage
    total_possible = group.users.count * readings_to_date
    return 0.0 if total_possible.zero?

    completed = completed_readings_to_date_count
    return 100 if completed == total_possible

    (completed.to_f / total_possible * 100).floor
  end

  private

  def total_readings
    query = challenge.readings
    query = query.where("scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
    query = query.where("scheduled_date <= ?", challenge.stats_end_date) if challenge.stats_end_date.present?
    @total_readings ||= query.count
  end

  def completed_readings_count
    query = UserReading
      .joins(:reading)
      .joins("JOIN user_group_enrollments uge ON uge.user_id = user_readings.user_id")
      .where(readings: { challenge_id: challenge.id })
      .where(uge: { group_id: group.id })
    query = query.where("readings.scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
    query = query.where("readings.scheduled_date <= ?", challenge.stats_end_date) if challenge.stats_end_date.present?
    @completed_readings_count ||= query.count
  end

  def readings_to_date
    query = challenge.readings.where("scheduled_date <= ?", effective_end_date)
    query = query.where("scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
    @readings_to_date ||= query.count
  end

  def completed_readings_to_date_count
    query = UserReading
      .joins(:reading)
      .joins("JOIN user_group_enrollments uge ON uge.user_id = user_readings.user_id")
      .where(readings: { challenge_id: challenge.id, scheduled_date: ..effective_end_date })
      .where(uge: { group_id: group.id })
    query = query.where("readings.scheduled_date >= ?", challenge.stats_start_date) if challenge.stats_start_date.present?
    @completed_readings_to_date_count ||= query.count
  end

  def effective_end_date
    challenge.stats_end_date.present? ? [ challenge.stats_end_date, current_date_in_challenge_timezone ].min : current_date_in_challenge_timezone
  end

  def current_date_in_challenge_timezone
    Time.current.in_time_zone(challenge.timezone).to_date
  end
end
