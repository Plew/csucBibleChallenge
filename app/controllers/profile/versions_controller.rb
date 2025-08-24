class Profile::VersionsController < Profile::BaseController
  # GET /profile/version/edit
  def edit
    @user = current_user
  end

  # PATCH /profile/version
  def update
    @user = current_user
    
    if @user.update(version_params)
      redirect_to edit_profile_version_path, notice: 'Bible version updated successfully.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def version_params
    params.require(:user).permit(:version)
  end
end