# frozen_string_literal: true

class Stats::ChallengeStatsComponent < ViewComponent::Base
  def initialize(top_readers_data:)
    @top_readers_data = top_readers_data
  end

  private

  attr_reader :top_readers_data
end