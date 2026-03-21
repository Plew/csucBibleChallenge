# frozen_string_literal: true

class Statistics::RecentBadgesComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(recent_badges:)
    @recent_badges = recent_badges
  end

  def render?
    recent_badges.any?
  end

  private

  attr_reader :recent_badges
end
