module Admin::UsersHelper
  def completed_days_for_user_challenge(user, challenge)
    # Get all readings for the challenge with their scheduled dates
    challenge_readings = challenge.readings.select(:id, :scheduled_date).index_by(&:id)

    # Get completed readings with their completion dates
    completed_readings = user.user_readings
      .where(reading_id: challenge_readings.keys)
      .pluck(:reading_id, :completed_on)

    # For each completed reading, determine day number and if it was on time
    completed_readings.map do |reading_id, completed_on|
      reading = challenge_readings[reading_id]
      day_number = (reading.scheduled_date - challenge.start_date).to_i

      # Compare completion date with scheduled date
      on_time = (completed_on == reading.scheduled_date)

      { day: day_number, on_time: on_time }
    end
  end

  def current_day_number_for_challenge(challenge)
    today = Time.use_zone(challenge.timezone) { Date.current }
    (today - challenge.start_date).to_i
  end

  # Returns an array of 15 booleans (one per day, most recent last) indicating
  # whether the user completed any reading on that date across all challenges.
  def last_15_days_activity(user)
    today = Date.current
    start_date = today - 14.days
    completed_dates = user.user_readings
      .where(completed_on: start_date..today)
      .distinct
      .pluck(:completed_on)
      .map(&:to_date)
      .to_set

    (0..14).map { |offset| completed_dates.include?(start_date + offset.days) }
  end
end
