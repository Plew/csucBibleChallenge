# frozen_string_literal: true

class BadgesDisplayComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(user:, challenge:)
    @user = user
    @challenge = challenge
  end

  def render?
    earned_badges.any?
  end

  private

  attr_reader :user, :challenge

  def earned_badges
    @earned_badges ||= user.user_badges
      .where(challenge: challenge)
      .select { |ub| BadgeCatalog.find(ub.badge_key) }
      .sort_by(&:created_at)
  end

  def earned_count
    earned_badges.size
  end

  def awarded_at(badge_key)
    earned_badges.find { |ub| ub.badge_key == badge_key }&.created_at
  end
end
