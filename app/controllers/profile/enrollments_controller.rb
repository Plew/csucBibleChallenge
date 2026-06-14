class Profile::EnrollmentsController < Profile::BaseController
  # GET /profile/enrollments
  def index
    @user_enrollment = current_user_enrollment
  end

  # DELETE /profile/enrollments/:id
  def destroy
    @user_enrollment = current_user.user_challenge_enrollments.find(params[:id])
    @user_enrollment.destroy
    redirect_to challenges_path, notice: "Successfully left the challenge."
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
