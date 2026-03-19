# frozen_string_literal: true

class PublicProfilesController < ApplicationController
  before_action :require_login
  before_action :set_user
  before_action :authorize_view

  def show
    # Get all verse likes for this user, grouped by date, most recent first
    @likes_by_date = @user.verse_likes
                          .includes(reading: :challenge)
                          .order(created_at: :desc)
                          .group_by { |like| like.created_at.to_date }

    # Find a shared challenge for badge display
    shared_challenges = current_user.challenges & @user.challenges
    @challenge = shared_challenges.first
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_view
    # Users can only view profiles of people in the same challenge
    shared_challenges = current_user.challenges & @user.challenges
    if shared_challenges.empty?
      redirect_to root_path, alert: t("public_profile.not_authorized")
    end
  end
end
