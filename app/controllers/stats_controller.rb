# frozen_string_literal: true

class StatsController < ApplicationController
  CACHE_EXPIRATION = 30.seconds

  def index
    current_challenge = current_user.challenges.first
    @challenge = current_challenge
    @sprint = load_sprint(current_challenge)
    @available_sprints = current_challenge&.sprints&.ordered || []
    date_range = @sprint&.date_range

    @challenge_summary_stats = cached_challenge_summary_stats(current_challenge)
    @personal_stats = cached_personal_stats(current_challenge, date_range)
    @top_readers_data = cached_top_readers(current_challenge, date_range)
    @participant_count = cached_participant_count(current_challenge)
    @top_groups_data = cached_top_groups(current_challenge, date_range)
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

  def load_sprint(challenge)
    return nil unless challenge

    # Check if sprint_id is in params (for URL-based selection)
    sprint_id = params[:sprint_id] || cookies[:sprint_id]

    # If "full" is selected, clear the cookie and return nil
    if sprint_id == "full"
      cookies.delete(:sprint_id)
      return nil
    end

    # Load the sprint if ID is present
    if sprint_id.present?
      sprint = challenge.sprints.find_by(id: sprint_id)
      # Store in cookie for persistence
      cookies[:sprint_id] = sprint_id if sprint
      return sprint
    end

    nil
  end

  def cached_top_readers(challenge, date_range = nil)
    return [] unless challenge

    cache_key = "stats/top_readers/#{challenge.id}"
    cache_key += "/#{date_range.first}_#{date_range.last}" if date_range

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      TopReadersStatistics.call(challenge: challenge, date_range: date_range)
    end
  end

  def cached_participant_count(challenge)
    return 0 unless challenge

    Rails.cache.fetch("stats/participant_count/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      challenge.users.count
    end
  end

  def cached_top_groups(challenge, date_range = nil)
    return [] unless challenge

    cache_key = "stats/top_groups/#{challenge.id}"
    cache_key += "/#{date_range.first}_#{date_range.last}" if date_range

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      TopGroupsStatistics.call(challenge: challenge, date_range: date_range)
    end
  end

  def cached_seven_day_window(challenge)
    return [] unless challenge

    Rails.cache.fetch("stats/seven_day_window/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      SevenDayWindowStatistics.call(challenge: challenge)
    end
  end

  def cached_challenge_summary_stats(challenge)
    return nil unless challenge

    Rails.cache.fetch("stats/challenge_summary/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      StatsChallengeSummaryStatistics.new(challenge)
    end
  end

  def cached_personal_stats(challenge, date_range = nil)
    return {} unless challenge

    cache_key = "stats/personal/#{current_user.id}/#{challenge.id}"
    cache_key += "/#{date_range.first}_#{date_range.last}" if date_range

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      calculate_personal_stats(current_user, challenge, date_range)
    end
  end

  def calculate_personal_stats(user, challenge, date_range = nil)
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    scheduled_query = challenge.readings.where("scheduled_date <= ?", current_date_in_tz)
    scheduled_query = scheduled_query.where(scheduled_date: date_range) if date_range
    scheduled_count = scheduled_query.count

    completed_query = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: challenge.id })
                         .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_query = completed_query.where(readings: { scheduled_date: date_range }) if date_range
    completed_count = completed_query.count

    completion_percentage = scheduled_count.zero? ? 0 : (completed_count.to_f / scheduled_count * 100).round

    # Calculate on-schedule percentage
    completed_readings = user.user_readings
                            .joins(:reading)
                            .where(readings: { challenge_id: challenge.id })
                            .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_readings = completed_readings.where(readings: { scheduled_date: date_range }) if date_range

    on_schedule_count = completed_readings
                       .where("date(user_readings.created_at) <= readings.scheduled_date")
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
