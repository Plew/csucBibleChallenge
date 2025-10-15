# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  def initialize(personal_stats:, top_readers_data:, participant_count:, top_groups_data:, seven_day_leaderboard_data:)
    @personal_stats = personal_stats
    @top_readers_data = top_readers_data
    @participant_count = participant_count
    @top_groups_data = top_groups_data
    @seven_day_leaderboard_data = seven_day_leaderboard_data
  end

  private

  attr_reader :personal_stats, :top_readers_data, :participant_count, :top_groups_data, :seven_day_leaderboard_data
end