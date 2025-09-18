# frozen_string_literal: true

class StatsController < ApplicationController
  def index
  end

  def challenge
    current_challenge = current_user.challenges.first
    @top_readers_data = TopReadersStatistics.call(challenge: current_challenge)
    @participant_count = current_challenge&.users&.count || 0
  end

  def group
    current_challenge = current_user.challenges.first
    @top_groups_data = TopGroupsStatistics.call(challenge: current_challenge)
  end

  def personal
  end

  def seven_day_window
    current_challenge = current_user.challenges.first
    @seven_day_leaderboard_data = SevenDayWindowStatistics.call(challenge: current_challenge)
  end
end