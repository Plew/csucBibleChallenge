class Profile::EnrollmentsController < Profile::BaseController
  # GET /profile/enrollments
  def index
    all_enrollments = current_user.user_challenge_enrollments.includes(:challenge).order("challenges.end_date DESC")
    @current_enrollments = all_enrollments.select { |e| !e.challenge.past? }
    @past_enrollments = all_enrollments.select { |e| e.challenge.past? }
  end

  # GET /profile/enrollments/:id
  def show
    @enrollment = current_user.user_challenge_enrollments.includes(:challenge).find(params[:id])
    @challenge = @enrollment.challenge

    unless @challenge.past?
      redirect_to profile_enrollments_path
      return
    end

    @stats = UserChallengeStats.new(current_user, @challenge)
    @group = current_user.groups.where(challenge: @challenge).first
    @completed_readings = current_user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: @challenge.id })
      .includes(reading: [])
      .order("readings.scheduled_date ASC")
  end

  # DELETE /profile/enrollments/:id
  def destroy
    @user_enrollment = current_user.user_challenge_enrollments.find(params[:id])
    @user_enrollment.destroy
    redirect_to profile_enrollments_path, notice: t("profile.left_challenge")
  end

  # GET /profile/enrollments/:id/delete_challenge_confirmation
  def delete_challenge_confirmation
    @user_enrollment = current_user.user_challenge_enrollments.find(params[:id])
    @challenge = @user_enrollment.challenge

    # Only allow challenge creator to delete
    unless @challenge.owned_by?(current_user)
      redirect_to profile_enrollments_path, alert: "Only the challenge creator can delete challenges."
      nil
    end
  end

  # DELETE /profile/enrollments/:id/delete_challenge
  def delete_challenge
    @user_enrollment = current_user.user_challenge_enrollments.find(params[:id])
    @challenge = @user_enrollment.challenge

    # Only allow challenge creator to delete
    unless @challenge.owned_by?(current_user)
      redirect_to profile_enrollments_path, alert: "Only the challenge creator can delete challenges."
      return
    end

    @challenge.destroy
    redirect_to challenges_path, notice: "Challenge has been deleted successfully."
  end
end
