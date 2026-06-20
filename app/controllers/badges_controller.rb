# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :require_login
  before_action :set_challenge

  def index
    @badges = BadgeCatalog.all
    @earned_counts = UserBadge
      .where(challenge: @challenge)
      .group(:badge_key)
      .count
    @my_earned = current_user.user_badges
      .where(challenge: @challenge)
      .pluck(:badge_key)
      .to_set
  end

  def show
    @badge = BadgeCatalog.find(params[:badge_key])
    unless @badge
      redirect_to badges_path, alert: I18n.t("badges.not_found")
      return
    end

    @awarded_users = UserBadge
      .where(challenge: @challenge, badge_key: @badge.key)
      .includes(user: [ :avatar_attachment, :avatar_blob ])
      .order(created_at: :asc)
  end

  private

  def set_challenge
    @challenge = current_user.active_challenge
    redirect_to root_path unless @challenge
  end
end
