class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :reset_password, :update_password ]

  def index
    @users = User.includes(:challenges).order(created_at: :desc)
    @challenges = Challenge.order(:name)

    if params[:search].present?
      @users = @users.where("email LIKE ? OR username LIKE ? OR id = ?", "%#{params[:search]}%", "%#{params[:search]}%", params[:search].to_i)
    end

    if params[:challenge_id].present?
      @users = @users.joins(:user_challenge_enrollments)
                     .where(user_challenge_enrollments: { challenge_id: params[:challenge_id] })
                     .distinct
    end

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@users), filename: "users-#{Date.today}.csv" }
    end
  end

  def show
    @user_readings = @user.user_readings
                          .includes(reading: :challenge)
                          .order("user_readings.completed_on DESC")
    @challenge_enrollments = @user.user_challenge_enrollments.includes(:challenge)
  end

  def reset_password
    new_password = SecureRandom.alphanumeric(12)
    @user.update_attribute(:password, new_password)

    redirect_to admin_users_path,
                notice: "Password reset for #{@user.email}. New password: #{new_password}"
  end

  def update_password
    new_password = params[:new_password]

    if new_password.blank?
      redirect_to admin_user_path(@user), alert: "Password cannot be blank"
      return
    end

    if new_password.length < 6
      redirect_to admin_user_path(@user), alert: "Password must be at least 6 characters"
      return
    end

    @user.update_attribute(:password, new_password)
    redirect_to admin_user_path(@user), notice: "Password updated successfully"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def generate_csv(users)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [ "ID", "Username", "Email", "Admin", "Version", "Daily Email", "Created At", "Challenges" ]

      users.each do |user|
        csv << [
          user.id,
          user.username,
          user.email,
          user.admin?,
          user.version,
          user.daily_email,
          user.created_at,
          user.challenges.map(&:name).join(", ")
        ]
      end
    end
  end
end
