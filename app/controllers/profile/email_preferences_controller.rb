class Profile::EmailPreferencesController < Profile::BaseController
  # GET /profile/email_preferences/edit
  def edit
    @user = current_user
  end

  # PATCH /profile/email_preferences
  def update
    @user = current_user
    
    if @user.update(email_preferences_params)
      redirect_to edit_profile_email_preferences_path, notice: 'Email preferences updated successfully.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def email_preferences_params
    if params[:user].present?
      params.require(:user).permit(:daily_email)
    else
      # When checkbox is unchecked, no user params are sent, so set daily_email to false
      ActionController::Parameters.new({ daily_email: false }).permit(:daily_email)
    end
  end
end