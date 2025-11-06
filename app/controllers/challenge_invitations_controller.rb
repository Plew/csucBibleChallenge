class ChallengeInvitationsController < ApplicationController
  before_action :set_challenge_by_token

  # GET /challenges/:token/join
  def show
    if logged_in?
      # Check if user is already enrolled in this challenge
      if current_user.challenges.include?(@challenge)
        redirect_to reading_path, notice: "You are already enrolled in #{@challenge.name}!"
        return
      end

      # Check if user is in any other challenge (one challenge at a time rule)
      if current_user.challenges.any?
        redirect_to root_path, alert: "You are already enrolled in a challenge. Leave your current challenge to join a new one."
        return
      end

      # Auto-enroll the logged-in user
      enrollment = @challenge.user_challenge_enrollments.new(user: current_user)
      if enrollment.save
        redirect_to reading_path, notice: "Successfully joined #{@challenge.name}!"
      else
        redirect_to root_path, alert: "Could not join challenge: #{enrollment.errors.full_messages.to_sentence}"
      end
    else
      # Store token and redirect to challenge show page for non-logged-in users
      session[:challenge_invitation_token] = @challenge.invitation_token
      redirect_to challenge_path(@challenge)
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
