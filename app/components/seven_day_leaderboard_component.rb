# frozen_string_literal: true

class SevenDayLeaderboardComponent < ViewComponent::Base
  def initialize(leaderboard_data:)
    @leaderboard_data = leaderboard_data
  end

  private

  attr_reader :leaderboard_data

  def reader_count
    leaderboard_data.length
  end
end
