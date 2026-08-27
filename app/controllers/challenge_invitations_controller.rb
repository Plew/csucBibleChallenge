class ChallengeInvitationsController < ApplicationController
  before_action :set_challenge_by_token

  # GET /challenges/:token/join
  def show
    if @challenge.locked?
      redirect_to challenge_path(@challenge), alert: I18n.t("challenges.signups_closed")
      return
    end

    # Store token in session for non-logged-in users or during authentication
    session[:challenge_invitation_token] = @challenge.invitation_token
    @is_enrolled = logged_in? && current_user.challenges.include?(@challenge)
    @user_count = @challenge.users.count
    @total_chapters = @challenge.readings.count
  end

  # POST /challenges/:token/accept
  def accept
    if @challenge.locked?
      redirect_to challenge_path(@challenge), alert: I18n.t("challenges.signups_closed")
      return
    end

    unless logged_in?
      session[:challenge_invitation_token] = @challenge.invitation_token
      redirect_to new_user_session_path, notice: "Please sign in to accept the challenge invitation."
      return
    end

    if current_user.challenges.include?(@challenge)
      set_active_challenge(@challenge)
      redirect_to reading_path, notice: "You are already enrolled in #{@challenge.name}!"
      return
    end

    enrollment = @challenge.user_challenge_enrollments.new(user: current_user)
    if enrollment.save
      set_active_challenge(@challenge)
      session.delete(:challenge_invitation_token)
      if @challenge.start_date <= Date.current && @challenge.end_date >= Date.current
        redirect_to reading_path, notice: "Successfully joined #{@challenge.name}!"
      else
        redirect_to challenge_path(@challenge), notice: "Successfully joined #{@challenge.name}!"
      end
    else
      redirect_to challenge_invitation_path(@challenge.invitation_token), alert: "Could not join challenge: #{enrollment.errors.full_messages.to_sentence}"
    end
  end

  private

  def set_challenge_by_token
    @challenge = Challenge.find_by(invitation_token: params[:token])
    unless @challenge
      redirect_to root_path, alert: "Invalid invitation link."
    end
  end
end
