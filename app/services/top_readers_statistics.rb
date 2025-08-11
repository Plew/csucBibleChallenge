# frozen_string_literal: true

class TopReadersStatistics
  def self.call
    new.call
  end

  def call
    users_with_stats = User.joins(:user_readings, :challenges)
                          .select(
                            'users.*',
                            'COUNT(user_readings.id) as total_chapters_read'
                          )
                          .where.not(challenges: { timezone: nil })
                          .group('users.id')
                          .limit(50)

    users_with_stats.map do |user|
      chapters_data = calculate_chapters_data(user)
      {
        user: user,
        total_chapters_read: user.total_chapters_read.to_i,
        chapters_completed: chapters_data[:completed],
        chapters_scheduled: chapters_data[:scheduled],
        completion_percentage: calculate_completion_percentage(user),
        avatar_url: avatar_url_for(user)
      }
    end.sort_by { |user_data| -user_data[:completion_percentage] }
  end

  private

  def calculate_completion_percentage(user)
    total_scheduled = 0
    total_completed = 0

    user.challenges.includes(:readings).each do |challenge|
      current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
      
      scheduled_count = challenge.readings
                                .where('scheduled_date <= ?', current_date_in_tz)
                                .count
      
      completed_count = user.user_readings
                           .joins(:reading)
                           .where(readings: { challenge_id: challenge.id })
                           .where('readings.scheduled_date <= ?', current_date_in_tz)
                           .count
      
      total_scheduled += scheduled_count
      total_completed += completed_count
    end

    return 0.0 if total_scheduled.zero?
    
    (total_completed.to_f / total_scheduled * 100).round(1)
  end

  def calculate_chapters_data(user)
    total_scheduled = 0
    total_completed = 0

    user.challenges.includes(:readings).each do |challenge|
      current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
      
      scheduled_count = challenge.readings
                                .where('scheduled_date <= ?', current_date_in_tz)
                                .count
      
      completed_count = user.user_readings
                           .joins(:reading)
                           .where(readings: { challenge_id: challenge.id })
                           .where('readings.scheduled_date <= ?', current_date_in_tz)
                           .count
      
      total_scheduled += scheduled_count
      total_completed += completed_count
    end

    {
      completed: total_completed,
      scheduled: total_scheduled
    }
  end

  def avatar_url_for(user)
    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(user.avatar.variant(:thumb), only_path: true)
    else
      nil
    end
  end
end