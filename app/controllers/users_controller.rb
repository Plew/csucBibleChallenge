class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :reset_key]

  def edit
  end

  def update
    @user.update(user_params)
    redirect_to edit_user_path, notice: 'User successfully updated.'
  end

  def reset_key
    @user.reset_key
    redirect_to edit_user_path, notice: 'User key successfully reset.'
  end

  def recover
    if request.post?
      if user_to_recover = User.find_by(key: params[:key])
        current_device.update!(user: user_to_recover)
        session[:user_id] = user_to_recover.id
        redirect_to edit_user_path, notice: 'Account recovered successfully!'
      else
        flash.now[:alert] = 'No account found with that key.'
        render :recover, status: :unprocessable_entity
      end
    end
    # GET request just renders the form
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name) # Add other permitted attributes as needed
  end
end