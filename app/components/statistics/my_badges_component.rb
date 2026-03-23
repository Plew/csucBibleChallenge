# frozen_string_literal: true

class Statistics::MyBadgesComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(user_badges:)
    @user_badges = user_badges
  end

  def render?
    earned_badges.any?
  end

  private

  attr_reader :user_badges

  def earned_badges
    @earned_badges ||= user_badges
      .select { |ub| BadgeCatalog.find(ub.badge_key) }
      .sort_by(&:created_at)
  end

  def earned_count
    earned_badges.size
  end
end
