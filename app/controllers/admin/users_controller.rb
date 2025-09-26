class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :reset_password]

  def index
    @users = User.all.order(created_at: :desc)
    
    if params[:search].present?
      @users = @users.where("email LIKE ? OR id = ?", "%#{params[:search]}%", params[:search].to_i)
    end
  end

  def show
  end

  def reset_password
    new_password = SecureRandom.alphanumeric(12)
    @user.update_attribute(:password, new_password)
    
    redirect_to admin_users_path, 
                notice: "Password reset for #{@user.email}. New password: #{new_password}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end