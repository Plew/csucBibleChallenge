class Profile::AvatarsController < Profile::BaseController
  # GET /profile/avatar/edit
  def edit
    @user = current_user
  end

  # PATCH /profile/avatar
  def update
    @user = current_user

    if @user.update(avatar_params)
      redirect_to edit_profile_avatar_path, notice: "Avatar updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def avatar_params
    params.require(:user).permit(:avatar)
  end
end
