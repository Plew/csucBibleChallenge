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
end
