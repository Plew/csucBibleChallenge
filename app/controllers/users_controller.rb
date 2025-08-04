class UsersController < ApplicationController
  before_action :require_login, only: [:edit, :update]
  # before_action :set_user, only: [:edit, :update] # This will need current_user

  # GET /users/sign_up
  def new
    @user = User.new # Assuming you have a User model
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user # Log in the user after successful registration
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /profile/edit
  def edit
    @user = current_user # Use current_user from ApplicationController
    @user_enrollment = current_user.user_challenge_enrollments.first # Fetch the current enrollment
    # Fallback if somehow current_user is nil (should not happen if require_login works)
    @user ||= User.new(username: "error_user", email: "error@example.com") 
  end

  # PATCH /profile
  def update
    @user = current_user
    # params_to_update = user_profile_params
    # if params_to_update[:password].blank? && params_to_update[:password_confirmation].blank?
    #   params_to_update.delete(:password)
    #   params_to_update.delete(:password_confirmation)
    #   params_to_update.delete(:current_password) # No need to check current_password if not updating password
    # end

    # if @user.update(params_to_update) # Simplified for now
    if @user.update(user_profile_update_params) # Implement user_profile_update_params
      redirect_to edit_user_profile_path, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
    # For now, just redirect with a notice
    # redirect_to edit_user_profile_path, notice: 'Profile update functionality not fully implemented yet.'
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :avatar)
  end

  def user_profile_update_params
    # Permit username. Password fields are optional.
    # If password is provided, current_password should also be required for validation (in model or here)
    params.require(:user).permit(:username, :current_password, :password, :password_confirmation, :avatar, :version)
  end

end 