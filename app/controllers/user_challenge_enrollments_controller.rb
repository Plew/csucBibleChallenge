class UserChallengeEnrollmentsController < ApplicationController
  before_action :require_login
  before_action :set_challenge, only: [ :create ]
  before_action :set_user_challenge_enrollment, only: [ :destroy ]

  # POST /challenges/:challenge_id/user_challenge_enrollments
  def create
    if @challenge.locked?
      redirect_to challenge_path(@challenge), alert: I18n.t("challenges.signups_closed")
      return
    end

    if current_user.challenges.include?(@challenge)
      set_active_challenge(@challenge)
      if @challenge.start_date <= Date.current && @challenge.end_date >= Date.current
        redirect_to reading_path, notice: "You are already enrolled in #{@challenge.name}."
      else
        redirect_to challenge_path(@challenge), notice: "You are already enrolled in #{@challenge.name}."
      end
      return
    end

    @enrollment = @challenge.user_challenge_enrollments.new(user: current_user)

    if @enrollment.save
      set_active_challenge(@challenge)
      # Redirect to reading page if challenge has started, otherwise to challenge page
      if @challenge.start_date <= Date.current && @challenge.end_date >= Date.current
        redirect_to reading_path, notice: "Joined #{@challenge.name}!"
      else
        redirect_to challenge_path(@challenge), notice: "Joined #{@challenge.name}!"
      end
    else
      # If coming from a dedicated join page, render :new might be appropriate
      # For now, redirecting to challenge details with an alert
      redirect_to challenge_path(@challenge), alert: "Could not join challenge: #{@enrollment.errors.full_messages.to_sentence}"
    end
  end

  # DELETE /user_challenge_enrollments/:id
  def destroy
    if @enrollment.user == current_user
      challenge_id = @enrollment.challenge_id
      @enrollment.destroy
      if session[:active_challenge_id] == challenge_id
        session.delete(:active_challenge_id)
        @current_active_challenge = nil
      end
      redirect_to challenges_path
    else
      # This case should ideally not be reachable if buttons are only shown to the correct user
      redirect_to challenges_path, alert: "You are not authorized to perform this action."
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Challenge not found."
  end

  def set_user_challenge_enrollment
    @enrollment = UserChallengeEnrollment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Enrollment not found."
  end
end
