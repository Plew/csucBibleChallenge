# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(challenge:, challenge_summary_stats:, personal_stats:, top_readers_data:, participant_count:, top_groups_data:, seven_day_leaderboard_data:, stat_window: nil, available_stat_windows: [])
    @challenge = challenge
    @challenge_summary_stats = challenge_summary_stats
    @personal_stats = personal_stats
    @top_readers_data = top_readers_data
    @participant_count = participant_count
    @top_groups_data = top_groups_data
    @seven_day_leaderboard_data = seven_day_leaderboard_data
    @stat_window = stat_window
    @available_stat_windows = available_stat_windows
  end

  private

  attr_reader :challenge, :challenge_summary_stats, :personal_stats, :top_readers_data, :participant_count, :top_groups_data, :seven_day_leaderboard_data, :stat_window, :available_stat_windows
end
