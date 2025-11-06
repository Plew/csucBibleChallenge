# frozen_string_literal: true

class Stats::GroupStatsComponent < ViewComponent::Base
  def initialize(top_groups_data:)
    @top_groups_data = top_groups_data
  end

  private

  attr_reader :top_groups_data
end
