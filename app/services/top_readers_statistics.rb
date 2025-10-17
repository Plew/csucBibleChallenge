# frozen_string_literal: true

class TopReadersStatistics
  def self.call(challenge:)
    new(challenge).call
  end

  def initialize(challenge)
    @challenge = challenge
  end

  def call
    return [] unless @challenge

    users_with_stats = User.joins(:challenges)
                           .left_joins(:user_readings)
                           .select(
                             'users.*',
                             'COUNT(user_readings.id) as total_chapters_read'
                           )
                           .where(challenges: { id: @challenge.id })
                           .where.not(challenges: { timezone: nil })
                           .group('users.id')

    # Eager load groups for the challenge to avoid N+1 queries
    user_ids = users_with_stats.map(&:id)
    group_names_map = build_group_names_map(user_ids)

    users_with_stats.map do |user|
      chapters_data = calculate_chapters_data(user)
      {
        user: user,
        total_chapters_read: user.total_chapters_read.to_i,
        chapters_completed: chapters_data[:completed],
        chapters_scheduled: chapters_data[:scheduled],
        completion_percentage: calculate_completion_percentage(user),
        on_schedule_percentage: calculate_on_schedule_percentage(user),
        avatar_url: avatar_url_for(user),
        group_name: group_names_map[user.id]
      }
    end.reject { |user_data| user_data[:chapters_completed].zero? }
      .sort_by { |user_data| -user_data[:completion_percentage] }
  end

  private

  def calculate_completion_percentage(user)
    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    scheduled_count = @challenge.readings
                              .where('scheduled_date <= ?', current_date_in_tz)
                              .count

    completed_count = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: @challenge.id })
                         .where('readings.scheduled_date <= ?', current_date_in_tz)
                         .count

    return 0 if scheduled_count.zero?

    (completed_count.to_f / scheduled_count * 100).round
  end

  def calculate_chapters_data(user)
    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    scheduled_count = @challenge.readings
                              .where('scheduled_date <= ?', current_date_in_tz)
                              .count

    completed_count = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: @challenge.id })
                         .where('readings.scheduled_date <= ?', current_date_in_tz)
                         .count

    {
      completed: completed_count,
      scheduled: scheduled_count
    }
  end

  def calculate_on_schedule_percentage(user)
    current_date_in_tz = Time.current.in_time_zone(@challenge.timezone).to_date

    # Completed readings up to current date
    completed_readings = user.user_readings
                            .joins(:reading)
                            .where(readings: { challenge_id: @challenge.id })
                            .where('readings.scheduled_date <= ?', current_date_in_tz)

    completed_count = completed_readings.count

    return 0 if completed_count.zero?

    # On-schedule readings (completed on or before scheduled date)
    on_schedule_count = completed_readings
                       .where('date(user_readings.created_at) <= readings.scheduled_date')
                       .count

    (on_schedule_count.to_f / completed_count * 100).round
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
      .select('user_group_enrollments.user_id', 'groups.name as group_name')

    # Build a hash mapping user_id to group_name
    user_group_enrollments.each_with_object({}) do |enrollment, hash|
      hash[enrollment.user_id] ||= enrollment.group_name
    end
  end
end