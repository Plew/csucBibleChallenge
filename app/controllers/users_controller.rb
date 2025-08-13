class UsersController < ApplicationController
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
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :avatar)
  end
end 