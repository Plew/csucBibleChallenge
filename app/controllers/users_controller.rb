class UsersController < ApplicationController
  # before_action :require_login, only: [:edit, :update] # Add this once auth is set up
  # before_action :set_user, only: [:edit, :update]

  # GET /users/sign_up
  def new
    @user = User.new # Assuming you have a User model
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      # Handle successful registration, e.g., log in, redirect, flash message
      # log_in @user # Placeholder for login helper
      redirect_to root_path, notice: 'Successfully registered!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /profile/edit
  def edit
    # @user would be set by set_user, assuming current_user for now
    # For now, if we don't have a current_user concept fully wired up,
    # we might need to fetch a placeholder or the first user for testing.
    # @user = current_user # Or User.first for placeholder
    @user = User.first # Placeholder for demonstration, assumes at least one user exists
    if @user.nil? # If no user, create a dummy one for form building
      @user = User.new(username: "demo_user", email: "demo@example.com")
    end
  end

  # PATCH /profile
  def update
    # @user would be set by set_user
    # if @user.update(user_profile_params)
    #   redirect_to edit_user_profile_path, notice: 'Profile updated successfully.'
    # else
    #   render :edit, status: :unprocessable_entity
    # end
    # For now, just redirect with a notice
    redirect_to edit_user_profile_path, notice: 'Profile update functionality not fully implemented yet.'
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  # def user_profile_params
  #   params.require(:user).permit(:username, :current_password, :password, :password_confirmation)
  #   # Adjust params based on what can be updated, e.g. no email change here
  # end

  # def set_user
  #   @user = current_user # Assuming a current_user helper
  # end

  # def require_login
  #   unless logged_in? # Assuming a logged_in? helper
  #     flash[:error] = "You must be logged in to access this section"
  #     redirect_to new_user_session_url # Or your login path
  #   end
  # end
end 