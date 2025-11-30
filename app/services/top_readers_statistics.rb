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

    users_with_stats = User.joins(:challenges)
                           .left_joins(:user_readings)
                           .select(
                             "users.*",
                             "COUNT(user_readings.id) as total_chapters_read",
                             "MAX(user_readings.created_at) as most_recent_reading_at"
                           )
                           .where(challenges: { id: @challenge.id })
                           .where.not(challenges: { timezone: nil })
                           .group("users.id")

    # Eager load groups for the challenge to avoid N+1 queries
    user_ids = users_with_stats.map(&:id)
    group_names_map = build_group_names_map(user_ids)

    users_with_stats.map do |user|
      chapters_data = calculate_chapters_data(user)
      most_recent_reading = parse_timestamp(user.most_recent_reading_at)
      {
        user: user,
        total_chapters_read: user.total_chapters_read.to_i,
        chapters_completed: chapters_data[:completed],
        chapters_scheduled: chapters_data[:scheduled],
        completion_percentage: calculate_completion_percentage(user),
        on_schedule_percentage: calculate_on_schedule_percentage(user),
        avatar_url: avatar_url_for(user),
        group_name: group_names_map[user.id],
        most_recent_reading_at: most_recent_reading
      }
    end.reject { |user_data| user_data[:chapters_completed].zero? }
      .select { |user_data| user_data[:completion_percentage] >= 50 }
      .sort_by { |user_data| [ -user_data[:completion_percentage], -user_data[:on_schedule_percentage], -(user_data[:most_recent_reading_at]&.to_i || 0) ] }
  end

  private

  def parse_timestamp(timestamp)
    return nil if timestamp.nil?

    # Handle both string and Time objects
    timestamp.is_a?(String) ? Time.zone.parse(timestamp) : timestamp
  end

  def calculate_completion_percentage(user)
    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    scheduled_query = @challenge.readings.where("scheduled_date <= ?", current_date_in_tz)
    scheduled_query = scheduled_query.where(scheduled_date: @date_range) if @date_range
    scheduled_count = scheduled_query.count

    completed_query = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: @challenge.id })
                         .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_query = completed_query.where(readings: { scheduled_date: @date_range }) if @date_range
    completed_count = completed_query.count

    return 0 if scheduled_count.zero?
    return 100 if completed_count == scheduled_count

    (completed_count.to_f / scheduled_count * 100).floor
  end

  def calculate_chapters_data(user)
    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    scheduled_query = @challenge.readings.where("scheduled_date <= ?", current_date_in_tz)
    scheduled_query = scheduled_query.where(scheduled_date: @date_range) if @date_range
    scheduled_count = scheduled_query.count

    completed_query = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: @challenge.id })
                         .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_query = completed_query.where(readings: { scheduled_date: @date_range }) if @date_range
    completed_count = completed_query.count

    {
      completed: completed_count,
      scheduled: scheduled_count
    }
  end

  def calculate_on_schedule_percentage(user)
    OnScheduleStatistic.new(user, @challenge, @date_range).percentage.floor
  end

  def avatar_url_for(user)
    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(user.avatar.variant(:thumb), only_path: true)
    else
      nil
    end
  end

  def build_group_names_map(user_ids)
    return {} unless @challenge

    # Fetch all user-group associations for this challenge in one query
    user_group_enrollments = UserGroupEnrollment
      .joins(:group)
      .where(user_id: user_ids, groups: { challenge_id: @challenge.id })
      .select("user_group_enrollments.user_id", "groups.name as group_name")

    # Build a hash mapping user_id to group_name
    user_group_enrollments.each_with_object({}) do |enrollment, hash|
      hash[enrollment.user_id] ||= enrollment.group_name
    end
  end
end
