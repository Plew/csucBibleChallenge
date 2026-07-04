class Manage::UsersController < Manage::BaseController
  before_action :set_user, only: [ :show, :remove, :remove_from_group, :change_password, :update_password, :promote, :demote ]
  before_action :require_challenge_creator!, only: [ :promote, :demote ]

  def index
    @users = filtered_users

    respond_to do |format|
      format.html
      format.csv do
        send_data generate_csv(@users),
                  filename: "challenge-#{@challenge.id}-users-#{Date.current}.csv",
                  type: "text/csv"
      end
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

  def promote
    if @user == @challenge.creator
      redirect_to challenge_manage_user_path(@challenge, @user), alert: t("manage.access_denied")
      return
    end

    enrollment = @user.user_challenge_enrollments.find_by(challenge: @challenge)
    enrollment.update!(role: "organizer")
    redirect_to challenge_manage_user_path(@challenge, @user), notice: t("manage.users.promoted", username: @user.username)
  end

  def demote
    if @user == @challenge.creator
      redirect_to challenge_manage_user_path(@challenge, @user), alert: t("manage.access_denied")
      return
    end

    enrollment = @user.user_challenge_enrollments.find_by(challenge: @challenge)
    enrollment.update!(role: "member")
    redirect_to challenge_manage_user_path(@challenge, @user), notice: t("manage.users.demoted", username: @user.username)
  end

  private

  def set_user
    @user = @challenge.users.find(params[:id])
  end

  def filtered_users
    users = @challenge.users.includes(:user_challenge_enrollments, :groups).order("user_challenge_enrollments.created_at DESC")

    if params[:search].present?
      users = users.where("email LIKE ? OR username LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:inactive_days].present?
      days = params[:inactive_days].to_i
      cutoff_date = days.days.ago.to_date
      active_user_ids = UserReading.joins(:reading)
        .where(readings: { challenge_id: @challenge.id })
        .where("user_readings.completed_on >= ?", cutoff_date)
        .distinct.pluck(:user_id)
      users = users.where.not(id: active_user_ids)
    end

    if params[:completion] == "100"
      users = users.where(id: fully_caught_up_user_ids)
    end

    users
  end

  # User IDs who have completed every reading scheduled on or before the
  # completion cutoff date — i.e. 100% complete through that date.
  def fully_caught_up_user_ids
    cutoff = completion_cutoff_date
    due_count = @challenge.readings.where("scheduled_date <= ?", cutoff).count
    return [] if due_count.zero?

    UserReading.joins(:reading)
      .where(readings: { challenge_id: @challenge.id })
      .where("readings.scheduled_date <= ?", cutoff)
      .group(:user_id)
      .having("COUNT(DISTINCT user_readings.reading_id) = ?", due_count)
      .pluck(:user_id)
  end

  # Challenge #9 is pinned to the end of its original schedule (2026-07-03,
  # the same rule as the banquet qualification), so readings added after that
  # date never change who counts as 100% complete. Other challenges use
  # yesterday in the challenge's timezone — today is excluded because it is
  # still in progress (mirrors PerfectRecordStatistics).
  def completion_cutoff_date
    return User::BANQUET_CUTOFF_DATE if @challenge.id == User::BANQUET_CHALLENGE_ID

    Time.current.in_time_zone(@challenge.timezone).to_date - 1
  end

  def generate_csv(users)
    require "csv"

    user_ids = users.map(&:id)
    completed_counts = UserReading.joins(:reading)
      .where(readings: { challenge_id: @challenge.id }, user_id: user_ids)
      .group(:user_id).count

    CSV.generate(headers: true) do |csv|
      csv << [ "Username", "Email", "Readings Completed" ]
      users.each do |user|
        csv << [ user.username, user.email, completed_counts[user.id] || 0 ]
      end
    end
  end

  def require_challenge_creator!
    unless @challenge.owner_or_site_admin?(current_user)
      redirect_to challenge_manage_dashboard_path(@challenge), alert: t("manage.access_denied")
    end
  end
end
