class Manage::UsersController < Manage::BaseController
  before_action :set_user, only: [ :show, :remove, :remove_from_group, :change_password, :update_password ]

  def index
    @users = @challenge.users.includes(:user_challenge_enrollments, :groups).order("user_challenge_enrollments.created_at DESC")

    if params[:search].present?
      @users = @users.where("email LIKE ? OR username LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:inactive_days].present?
      days = params[:inactive_days].to_i
      cutoff_date = days.days.ago.to_date
      active_user_ids = UserReading.joins(:reading)
        .where(readings: { challenge_id: @challenge.id })
        .where("user_readings.completed_on >= ?", cutoff_date)
        .distinct.pluck(:user_id)
      @users = @users.where.not(id: active_user_ids)
    end
  end

  def show
    @enrollment = @user.user_challenge_enrollments.find_by(challenge: @challenge)
    @user_group = @user.groups.where(challenge: @challenge).first
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

  def remove_from_group
    group_enrollments = @user.user_group_enrollments.joins(:group).where(groups: { challenge_id: @challenge.id })
    if group_enrollments.any?
      group_enrollments.delete_all
      redirect_to challenge_manage_user_path(@challenge, @user), notice: t("manage.users.removed_from_group", username: @user.username)
    else
      redirect_to challenge_manage_user_path(@challenge, @user), alert: t("manage.users.not_in_group")
    end
  end

  def bulk_remove_from_groups
    user_ids = params[:user_ids] || []
    if user_ids.empty?
      redirect_to challenge_manage_users_path(@challenge), alert: t("manage.users.no_users_selected")
      return
    end

    group_ids = @challenge.groups.pluck(:id)
    removed_count = UserGroupEnrollment.where(user_id: user_ids, group_id: group_ids).delete_all
    redirect_to challenge_manage_users_path(@challenge), notice: t("manage.users.removed_from_groups", count: removed_count)
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
