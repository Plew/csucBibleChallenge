# frozen_string_literal: true

class StatsController < ApplicationController
  CACHE_EXPIRATION = 30.seconds

  def index
    current_challenge = current_user.challenges.first
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
    return TopReadersStatistics.call(challenge: nil) unless challenge

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
    return TopGroupsStatistics.call(challenge: nil) unless challenge

    Rails.cache.fetch("stats/top_groups/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      TopGroupsStatistics.call(challenge: challenge)
    end
  end

  def cached_seven_day_window(challenge)
    return SevenDayWindowStatistics.call(challenge: nil) unless challenge

    Rails.cache.fetch("stats/seven_day_window/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      SevenDayWindowStatistics.call(challenge: challenge)
    end
  end
end