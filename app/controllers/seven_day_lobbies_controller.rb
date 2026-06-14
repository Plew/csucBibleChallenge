# frozen_string_literal: true

class SevenDayLobbiesController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :require_enrollment
  before_action :require_admin, only: [ :start, :clear_lobby, :add_all_eligibles ]

  def show
    @lobby_participants = SevenDayLobby.participants_for_challenge(@challenge)
    @user_in_lobby = SevenDayLobby.user_in_lobby?(current_user, @challenge)
    @user_qualifies = user_qualifies_for_lobby?
  end

  def join
    unless user_qualifies_for_lobby?
      redirect_to challenge_seven_day_lobby_path(@challenge), alert: t("seven_day_lobby.not_qualified")
      return
    end

    lobby_entry = SevenDayLobby.find_or_create_by(user: current_user, challenge: @challenge)

    if lobby_entry.persisted?
      redirect_to challenge_seven_day_lobby_path(@challenge), notice: t("seven_day_lobby.joined_successfully")
    else
      redirect_to challenge_seven_day_lobby_path(@challenge), alert: t("seven_day_lobby.join_failed")
    end
  end

  def leave
    lobby_entry = SevenDayLobby.find_by(user: current_user, challenge: @challenge)

    if lobby_entry&.destroy
      redirect_to challenge_seven_day_lobby_path(@challenge), notice: t("seven_day_lobby.left_successfully")
    else
      redirect_to challenge_seven_day_lobby_path(@challenge), alert: t("seven_day_lobby.leave_failed")
    end
  end

  def start
    lobby_participants = SevenDayLobby.participants_for_challenge(@challenge)

    if lobby_participants.empty?
      redirect_to challenge_seven_day_lobby_path(@challenge), alert: t("seven_day_lobby.no_participants")
      return
    end

    # Clear the lobby after getting participants (game is starting)
    SevenDayLobby.where(challenge: @challenge).destroy_all

    # Get animation type from params (default to "pacman")
    animation_type = params[:animation_type] || "pacman"

    # Redirect to the draw page with lobby participants
    redirect_to admin_seven_day_winner_draw_path(
      challenge_id: @challenge.id,
      user_ids: lobby_participants.map(&:id),
      animation_type: animation_type
    )
  end

  def clear_lobby
    SevenDayLobby.where(challenge: @challenge).destroy_all
    redirect_to challenge_seven_day_lobby_path(@challenge), notice: t("seven_day_lobby.lobby_cleared")
  end

  def add_all_eligibles
    eligible_users = find_all_eligible_users
    added_count = 0

    eligible_users.each do |user|
      unless SevenDayLobby.user_in_lobby?(user, @challenge)
        SevenDayLobby.create(user: user, challenge: @challenge)
        added_count += 1
      end
    end

    redirect_to challenge_seven_day_lobby_path(@challenge),
                notice: t("seven_day_lobby.added_all_eligibles", count: added_count)
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def require_enrollment
    unless current_user.challenges.include?(@challenge)
      redirect_to challenges_path, alert: t("seven_day_lobby.must_be_enrolled")
    end
  end

  def user_qualifies_for_lobby?
    # User must have 100% completion for the last 7 days
    stats = SevenDayWindowStatistics.new(@challenge).calculate_seven_day_data(current_user)
    stats[:completion_percentage] == 100
  end

  def find_all_eligible_users
    seven_day_stats = SevenDayWindowStatistics.new(@challenge)
    @challenge.users.select do |user|
      stats = seven_day_stats.calculate_seven_day_data(user)
      stats[:completion_percentage] == 100
    end
  end

  def require_admin
    unless @challenge.owner_or_site_admin?(current_user)
      redirect_to challenge_seven_day_lobby_path(@challenge), alert: t("seven_day_lobby.admin_only")
    end
  end
end
