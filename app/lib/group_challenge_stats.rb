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
    (completed.to_f / total_possible * 100).round(1)
  end

  # Completion percentage relative to readings scheduled up to current date for all group members
  def on_track_percentage
    total_possible = group.users.count * readings_to_date
    return 0.0 if total_possible.zero?
    
    completed = completed_readings_to_date_count
    (completed.to_f / total_possible * 100).round(1)
  end

  private

  def total_readings
    @total_readings ||= challenge.readings.count
  end

  def completed_readings_count
    @completed_readings_count ||= UserReading
      .joins(:reading)
      .joins("JOIN user_group_enrollments uge ON uge.user_id = user_readings.user_id")
      .where(readings: { challenge_id: challenge.id })
      .where(uge: { group_id: group.id })
      .count
  end

  def readings_to_date
    @readings_to_date ||= challenge.readings
      .where('scheduled_date <= ?', current_date_in_challenge_timezone)
      .count
  end

  def completed_readings_to_date_count
    @completed_readings_to_date_count ||= UserReading
      .joins(:reading)
      .joins("JOIN user_group_enrollments uge ON uge.user_id = user_readings.user_id")
      .where(readings: { challenge_id: challenge.id, scheduled_date: ..current_date_in_challenge_timezone })
      .where(uge: { group_id: group.id })
      .count
  end

  def current_date_in_challenge_timezone
    Time.current.in_time_zone(challenge.timezone).to_date
  end
end