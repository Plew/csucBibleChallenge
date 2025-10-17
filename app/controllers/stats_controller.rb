# frozen_string_literal: true

class StatsController < ApplicationController
  CACHE_EXPIRATION = 30.seconds

  def index
    current_challenge = current_user.challenges.first
    @personal_stats = cached_personal_stats(current_challenge)
    @top_readers_data = cached_top_readers(current_challenge)
    @participant_count = cached_participant_count(current_challenge)
    @top_groups_data = cached_top_groups(current_challenge)
    @seven_day_leaderboard_data = cached_seven_day_window(current_challenge)
  end

  def challenge
    current_challenge = current_user.challenges.first
    @top_readers_data = cached_top_readers(current_challenge)
    @participant_count = cached_participant_count(current_challenge)
  end

  def group
    current_challenge = current_user.challenges.first
    @top_groups_data = cached_top_groups(current_challenge)
  end

  def personal
  end

  def seven_day_window
    current_challenge = current_user.challenges.first
    @seven_day_leaderboard_data = cached_seven_day_window(current_challenge)
  end

  private

  def cached_top_readers(challenge)
    return [] unless challenge

    Rails.cache.fetch("stats/top_readers/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      TopReadersStatistics.call(challenge: challenge)
    end
  end

  def cached_participant_count(challenge)
    return 0 unless challenge

    Rails.cache.fetch("stats/participant_count/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      challenge.users.count
    end
  end

  def cached_top_groups(challenge)
    return [] unless challenge

    Rails.cache.fetch("stats/top_groups/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      TopGroupsStatistics.call(challenge: challenge)
    end
  end

  def cached_seven_day_window(challenge)
    return [] unless challenge

    Rails.cache.fetch("stats/seven_day_window/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      SevenDayWindowStatistics.call(challenge: challenge)
    end
  end

  def cached_personal_stats(challenge)
    return {} unless challenge

    Rails.cache.fetch("stats/personal/#{current_user.id}/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      calculate_personal_stats(current_user, challenge)
    end
  end

  def calculate_personal_stats(user, challenge)
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    scheduled_count = challenge.readings
                              .where('scheduled_date <= ?', current_date_in_tz)
                              .count

    completed_count = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: challenge.id })
                         .where('readings.scheduled_date <= ?', current_date_in_tz)
                         .count

    completion_percentage = scheduled_count.zero? ? 0 : (completed_count.to_f / scheduled_count * 100).round

    # Calculate on-schedule percentage
    completed_readings = user.user_readings
                            .joins(:reading)
                            .where(readings: { challenge_id: challenge.id })
                            .where('readings.scheduled_date <= ?', current_date_in_tz)

    on_schedule_count = completed_readings
                       .where('date(user_readings.created_at) <= readings.scheduled_date')
                       .count

    on_schedule_percentage = completed_count.zero? ? 0 : (on_schedule_count.to_f / completed_count * 100).round

    {
      chapters_completed: completed_count,
      chapters_scheduled: scheduled_count,
      completion_percentage: completion_percentage,
      on_schedule_percentage: on_schedule_percentage
    }
  end
end