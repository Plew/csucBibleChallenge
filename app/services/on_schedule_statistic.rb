# frozen_string_literal: true

class OnScheduleStatistic
  attr_reader :user, :challenge, :date_range

  def initialize(user, challenge, date_range = nil)
    @user = user
    @challenge = challenge
    @date_range = date_range
  end

  # Batch calculation for multiple users (avoids N+1 queries)
  # Returns hash: { user_id => percentage }
  def self.batch_percentages(user_ids, challenge)
    return {} if user_ids.empty?

    current_date = Time.current.in_time_zone(challenge.timezone).to_date

    # Get total scheduled readings (same for all users)
    total_scheduled = challenge.readings
                              .where("scheduled_date <= ?", current_date)
                              .count

    return user_ids.index_with { 0 } if total_scheduled.zero?

    # Single query to get on-schedule counts for all users
    results = User.joins("LEFT JOIN user_readings ON user_readings.user_id = users.id")
                  .joins("LEFT JOIN readings ON readings.id = user_readings.reading_id
                          AND readings.challenge_id = #{challenge.id}
                          AND DATE(user_readings.completed_on) = readings.scheduled_date
                          AND readings.scheduled_date <= '#{current_date}'")
                  .where(id: user_ids)
                  .group("users.id")
                  .select("users.id", "COUNT(DISTINCT readings.id) as on_schedule_count")

    # Build hash of percentages
    percentages = {}
    results.each do |result|
      on_schedule_count = result.on_schedule_count
      if on_schedule_count == total_scheduled
        percentages[result.id] = 100
      else
        percentages[result.id] = (on_schedule_count.to_f / total_scheduled * 100).round(2)
      end
    end

    # Fill in 0 for users not in results (no on-schedule readings)
    user_ids.each do |user_id|
      percentages[user_id] ||= 0
    end

    percentages
  end

  # Percentage of scheduled readings (up to current date) that were completed on time
  # Considers the challenge's timezone when determining if reading was "on schedule"
  # If a user skips a day, it counts as not being on time (denominator includes all scheduled readings)
  def percentage
    return 0 if scheduled_readings_to_date.zero?

    on_schedule = on_schedule_count
    scheduled = scheduled_readings_to_date
    return 100 if on_schedule == scheduled

    (on_schedule.to_f / scheduled * 100).round(2)
  end

  # Count of readings completed on their scheduled date (only for readings scheduled up to current date)
  def on_schedule_count
    query = user_readings_for_challenge
      .joins(:reading)
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .where("readings.scheduled_date <= ?", current_date_in_challenge_timezone)
    query = query.where(readings: { scheduled_date: date_range }) if date_range
    query.count
  end

  # Total count of completed readings for this challenge
  def total_completed_count
    user_readings_for_challenge.count
  end

  # Count of readings scheduled up to the current date (in challenge timezone)
  def scheduled_readings_to_date
    query = challenge.readings.where("scheduled_date <= ?", current_date_in_challenge_timezone)
    query = query.where(scheduled_date: date_range) if date_range
    query.count
  end

  private

  def user_readings_for_challenge
    user.user_readings
        .joins(:reading)
        .where(readings: { challenge_id: challenge.id })
  end

  def current_date_in_challenge_timezone
    Time.current.in_time_zone(challenge.timezone).to_date
  end
end
