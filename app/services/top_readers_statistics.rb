# frozen_string_literal: true

class TopReadersStatistics
  def self.call(challenge:, date_range: nil)
    new(challenge, date_range).call
  end

  def initialize(challenge, date_range = nil)
    @challenge = challenge
    @date_range = date_range
  end

  def call
    return [] unless @challenge

    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    # Single query: get scheduled count (same for all users)
    scheduled_query = @challenge.readings.where("scheduled_date <= ?", current_date_in_tz)
    scheduled_query = scheduled_query.where(scheduled_date: @date_range) if @date_range
    scheduled_count = scheduled_query.count
    return [] if scheduled_count.zero?

    # Single query: get all reading IDs for the challenge up to today
    reading_ids = scheduled_query.pluck(:id)

    # Single query: batch completion counts per user
    completion_counts = UserReading
      .where(reading_id: reading_ids)
      .joins("INNER JOIN user_challenge_enrollments ON user_challenge_enrollments.user_id = user_readings.user_id AND user_challenge_enrollments.challenge_id = #{@challenge.id}")
      .group(:user_id)
      .count

    # Filter to users with >0 completions and >=50% completion
    qualifying_user_ids = completion_counts.select { |_uid, count|
      count > 0 && (count >= scheduled_count || (count.to_f / scheduled_count * 100).floor >= 50)
    }.keys

    return [] if qualifying_user_ids.empty?

    # Single query: batch on-schedule counts per user
    on_schedule_counts = UserReading
      .joins(:reading)
      .where(reading_id: reading_ids, user_id: qualifying_user_ids)
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .group(:user_id)
      .count

    # Single query: most recent reading timestamp per user
    most_recent_readings = UserReading
      .where(reading_id: reading_ids, user_id: qualifying_user_ids)
      .group(:user_id)
      .maximum(:created_at)

    # Single query: load all qualifying users
    users = User.where(id: qualifying_user_ids).index_by(&:id)

    # Single query: group names map
    group_names_map = build_group_names_map(qualifying_user_ids)

    # Build results without any per-user queries
    qualifying_user_ids.filter_map do |user_id|
      user = users[user_id]
      next unless user

      completed = completion_counts[user_id] || 0
      on_schedule = on_schedule_counts[user_id] || 0

      completion_pct = if completed >= scheduled_count
        100
      else
        (completed.to_f / scheduled_count * 100).floor
      end

      on_schedule_pct = if scheduled_count.zero?
        0
      elsif on_schedule >= scheduled_count
        100
      else
        (on_schedule.to_f / scheduled_count * 100).floor
      end

      {
        user: user,
        total_chapters_read: completed,
        chapters_completed: completed,
        chapters_scheduled: scheduled_count,
        completion_percentage: completion_pct,
        on_schedule_percentage: on_schedule_pct,
        avatar_url: nil,
        group_name: group_names_map[user_id],
        most_recent_reading_at: most_recent_readings[user_id]
      }
    end.sort_by { |d| [ -d[:completion_percentage], -d[:on_schedule_percentage], -(d[:most_recent_reading_at]&.to_i || 0) ] }
  end

  private

  def build_group_names_map(user_ids)
    return {} unless @challenge

    UserGroupEnrollment
      .joins(:group)
      .where(user_id: user_ids, groups: { challenge_id: @challenge.id })
      .select("user_group_enrollments.user_id", "groups.name as group_name")
      .each_with_object({}) do |enrollment, hash|
        hash[enrollment.user_id] ||= enrollment.group_name
      end
  end
end
