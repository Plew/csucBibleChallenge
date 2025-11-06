class Profile::PasswordsController < Profile::BaseController
  # GET /profile/password/edit
  def edit
    @user = current_user
  end

  # PATCH /profile/password
  def update
    @user = current_user

    if @user.update(password_params)
      redirect_to edit_profile_password_path, notice: "Password updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
