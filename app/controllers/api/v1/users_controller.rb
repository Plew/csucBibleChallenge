class Api::V1::UsersController < Api::BaseController
  # POST /api/v1/users
  def create
    user = User.new(user_params)

    if user.save
      render json: user, status: :created, except: [:password_digest]
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
