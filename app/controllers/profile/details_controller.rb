class Profile::DetailsController < Profile::BaseController
  # GET /profile/details/edit
  def edit
    @user = current_user
  end

  # PATCH /profile/details
  def update
    @user = current_user

    if @user.update(details_params)
      redirect_to edit_profile_details_path, notice: "Profile details updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def details_params
    params.require(:user).permit(:username, :version, :avatar)
  end
end
