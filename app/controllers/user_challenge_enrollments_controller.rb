class UserChallengeEnrollmentsController < ApplicationController
  before_action :require_login
  before_action :set_challenge, only: [:create]
  before_action :set_user_challenge_enrollment, only: [:destroy]

  # POST /challenges/:challenge_id/user_challenge_enrollments
  def create
    # Ensure user is not already in a challenge if we strictly enforce one challenge at a time via UI
    if current_user.challenges.any?
      redirect_to root_path, alert: 'You are already enrolled in a challenge. Leave your current challenge to join a new one.'
      return
    end

    @enrollment = @challenge.user_challenge_enrollments.new(user: current_user)
    # In the future, if a user can select a group upon joining:
    # @enrollment.group_id = params[:group_id] # Ensure group_id is permitted and valid

    if @enrollment.save
      redirect_to challenge_path(@challenge) #, notice: "Successfully joined #{@challenge.name}!"
    else
      # If coming from a dedicated join page, render :new might be appropriate
      # For now, redirecting to challenge details with an alert
      redirect_to challenge_path(@challenge), alert: "Could not join challenge: #{@enrollment.errors.full_messages.to_sentence}"
    end
  end

  # DELETE /user_challenge_enrollments/:id
  def destroy
    if @enrollment.user == current_user
      @enrollment.destroy
      redirect_to challenges_path
    else
      # This case should ideally not be reachable if buttons are only shown to the correct user
      redirect_to challenges_path, alert: 'You are not authorized to perform this action.'
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Challenge not found.'
  end

  def set_user_challenge_enrollment
    @enrollment = UserChallengeEnrollment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Enrollment not found.'
  end
end 