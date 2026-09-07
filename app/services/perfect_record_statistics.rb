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
    effective_start = @challenge.effective_stats_start_date
    effective_end = [ @challenge.effective_stats_end_date, current_date_in_tz - 1.day ].min
    return { users: [], days_count: 0 } if effective_end < effective_start

    eval_range = effective_start..effective_end

    # Count readings scheduled before today (within stats date range)
    scheduled_count = @challenge.readings
      .where(scheduled_date: eval_range)
      .count

    return { users: [], days_count: 0 } if scheduled_count.zero?

    # Days in the stats window so far (excluding today)
    days_count = (effective_end - effective_start).to_i + 1

    reading_ids = @challenge.readings
      .where(scheduled_date: eval_range)
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
