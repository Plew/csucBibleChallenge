class Profile::EnrollmentsController < Profile::BaseController
  # GET /profile/enrollments
  def index
    @user_enrollment = current_user_enrollment
  end

  # DELETE /profile/enrollments/:id
  def destroy
    @user_enrollment = current_user.user_challenge_enrollments.find(params[:id])
    @user_enrollment.destroy
    redirect_to profile_enrollments_path, notice: 'Successfully left the challenge.'
  end
end