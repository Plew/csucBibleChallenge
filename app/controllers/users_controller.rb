class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :reset_key]

  def edit
  end

  def update
    @user.update(user_params)
    redirect_to edit_user_path, notice: 'User was successfully updated.'
  end

  def reset_key
    @user.reset_key
    redirect_to edit_user_path, notice: 'User key was successfully reset.'
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name) # Add other permitted attributes as needed
  end
end