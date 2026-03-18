# frozen_string_literal: true

class PerfectRecordStatistics
  def self.call(challenge:)
    new(challenge).call
  end

  def initialize(challenge)
    @challenge = challenge
  end

  def call
    return { users: [], days_count: 0 } unless @challenge

    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    # Count readings scheduled before today (exclude today)
    scheduled_count = @challenge.readings
      .where("scheduled_date < ?", current_date_in_tz)
      .count

    return { users: [], days_count: 0 } if scheduled_count.zero?

    # Days in the challenge so far (excluding today)
    days_count = (current_date_in_tz - @challenge.start_date).to_i

    reading_ids = @challenge.readings
      .where("scheduled_date < ?", current_date_in_tz)
      .pluck(:id)

    return { users: [], days_count: days_count } if reading_ids.empty?

    # Single efficient query:
    # Find user IDs who have completed ALL scheduled readings AND all on time
    # by counting total completions and on-time completions per user
    perfect_user_ids = UserReading
      .joins(:reading)
      .where(reading_id: reading_ids)
      .where(readings: { challenge_id: @challenge.id })
      .group(:user_id)
      .having(
        "COUNT(DISTINCT user_readings.reading_id) = ? AND COUNT(DISTINCT CASE WHEN DATE(user_readings.completed_on) = readings.scheduled_date THEN user_readings.reading_id END) = ?",
        scheduled_count, scheduled_count
      )
      .pluck(:user_id)

    return { users: [], days_count: days_count } if perfect_user_ids.empty?

    # Only include users enrolled in this challenge
    enrolled_ids = UserChallengeEnrollment
      .where(challenge_id: @challenge.id, user_id: perfect_user_ids)
      .pluck(:user_id)

    users = User.where(id: enrolled_ids).order(:username).select(:id, :username)

    {
      users: users,
      days_count: days_count
    }
  end
end
