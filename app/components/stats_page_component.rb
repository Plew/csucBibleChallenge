# frozen_string_literal: true

class StatsPageComponent < ViewComponent::Base
  def initialize(top_readers_data:, participant_count:, top_groups_data:, seven_day_leaderboard_data:)
    @top_readers_data = top_readers_data
    @participant_count = participant_count
    @top_groups_data = top_groups_data
    @seven_day_leaderboard_data = seven_day_leaderboard_data
  end

  private

  attr_reader :top_readers_data, :participant_count, :top_groups_data, :seven_day_leaderboard_data
end