class Manage::UsersController < Manage::BaseController
  before_action :set_user, only: [ :show, :remove, :change_password, :update_password ]

  def index
    @users = @challenge.users.includes(:user_challenge_enrollments).order("user_challenge_enrollments.created_at DESC")

    if params[:search].present?
      @users = @users.where("email LIKE ? OR username LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
  end

  def show
    @enrollment = @user.user_challenge_enrollments.find_by(challenge: @challenge)
  end

  def remove
    enrollment = @user.user_challenge_enrollments.find_by(challenge: @challenge)
    if enrollment
      enrollment.destroy
      redirect_to challenge_manage_users_path(@challenge), notice: t("manage.users.removed", username: @user.username)
    else
      redirect_to challenge_manage_users_path(@challenge), alert: t("manage.users.not_enrolled")
    end
  end

  def change_password
  end

  def update_password
    new_password = params[:new_password]

    if new_password.blank?
      redirect_to challenge_manage_user_path(@challenge, @user), alert: t("manage.users.password_blank")
      return
    end

    if new_password.length < 6
      redirect_to challenge_manage_user_path(@challenge, @user), alert: t("manage.users.password_too_short")
      return
    end

    @user.update_attribute(:password, new_password)
    redirect_to challenge_manage_user_path(@challenge, @user), notice: t("manage.users.password_updated")
  end

  private

  def set_user
    @user = @challenge.users.find(params[:id])
  end
end
