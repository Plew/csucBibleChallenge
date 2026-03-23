# frozen_string_literal: true

class SevenDayWindowStatistics
  def self.call(challenge: nil)
    new(challenge).call
  end

  def initialize(challenge = nil)
    @challenge = challenge
  end

  def call
    return [] unless @challenge

    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date
    seven_days_ago = current_date_in_tz - 6.days

    # Single query: reading IDs in the 7-day window
    scheduled_readings = @challenge.readings.where(scheduled_date: seven_days_ago..current_date_in_tz)
    reading_ids = scheduled_readings.pluck(:id)
    scheduled_count = reading_ids.length

    return [] if scheduled_count.zero?

    # Single query: get all enrolled user IDs
    user_ids = UserChallengeEnrollment.where(challenge_id: @challenge.id).pluck(:user_id)
    return [] if user_ids.empty?

    # Single query: batch completion counts per user for 7-day window
    completion_counts = UserReading
      .where(reading_id: reading_ids, user_id: user_ids)
      .group(:user_id)
      .count

    # Only users with 100% completion in the window
    perfect_user_ids = completion_counts.select { |_uid, count| count >= scheduled_count }.keys
    return [] if perfect_user_ids.empty?

    # Single query: batch on-schedule counts for perfect users
    on_schedule_counts = UserReading
      .joins(:reading)
      .where(reading_id: reading_ids, user_id: perfect_user_ids)
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .group(:user_id)
      .count

    # Single query: load user names
    users = User.where(id: perfect_user_ids).select(:id, :name).index_by(&:id)

    perfect_user_ids.filter_map do |user_id|
      user = users[user_id]
      next unless user

      on_schedule = on_schedule_counts[user_id] || 0
      on_schedule_pct = if on_schedule >= scheduled_count
        100
      else
        (on_schedule.to_f / scheduled_count * 100).floor
      end

      {
        name: user.name,
        completion_percentage: 100,
        on_schedule_percentage: on_schedule_pct,
        completed_days: scheduled_count,
        total_days: scheduled_count
      }
    end.sort_by { |data| -data[:on_schedule_percentage] }
  end
end
