class GroupsController < ApplicationController
  before_action :require_login
  before_action :set_enrollment_and_challenge

  # GET /groups
  def index
    @user_group = current_user.groups.where(challenge_id: @challenge.id).first
    if @user_group
      redirect_to group_path(@user_group)
      return
    end

    @groups = @challenge.groups.order(:name)
                  .includes(user_group_enrollments: { user: [ :avatar_attachment, :avatar_blob ] })
                  .to_a
  end

  # GET /groups/new
  def new
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to groups_path, alert: "You are already in a group."
      return
    end
    @group = @challenge.groups.new
  end

  # POST /groups
  def create
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to groups_path, alert: "You are already in a group."
      return
    end
    @group = @challenge.groups.new(group_params.merge(creator: current_user))
    if @group.save
      UserGroupEnrollment.create!(user: current_user, group: @group)
      redirect_to groups_path
    else
      render :new, status: :unprocessable_content
    end
  end

  # GET /groups/:id/confirm_destroy
  def confirm_destroy
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to groups_path, alert: "Only the group creator can perform this action."
      return
    end
    @other_members = @group.user_group_enrollments.where.not(user_id: current_user.id)
    unless @other_members.exists?
      redirect_to groups_path, alert: "No other members to remove."
      nil
    end
  end

  # POST /groups/leave
  def leave
    @user_group = current_user.groups.where(challenge_id: @challenge.id).first
    unless @user_group
      redirect_to groups_path, alert: "You are not in a group."
      return
    end
    group = @user_group
    if group.creator == current_user
      other_members = group.user_group_enrollments.where.not(user_id: current_user.id)
      if other_members.exists?
        redirect_to confirm_destroy_group_path(group)
        return
      else
        group.destroy
        redirect_to groups_path
        return
      end
    end
    UserGroupEnrollment.find_by(user: current_user, group: group)&.destroy
    redirect_to groups_path
  end

  # POST /groups/:id/join
  def join
    group = @challenge.groups.find(params[:id])
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to groups_path, alert: "You are already in a group."
      return
    end
    if group.closed_to_new_members
      redirect_to groups_path, alert: "This group is closed to new members."
      return
    end
    UserGroupEnrollment.create!(user: current_user, group: group)
    redirect_to groups_path
  rescue ActiveRecord::RecordInvalid => e
    redirect_to groups_path, alert: e.record.errors.full_messages.to_sentence
  end

  # POST /groups/:id/destroy_and_leave
  def destroy_and_leave
    group = @challenge.groups.find(params[:id])
    unless group.creator == current_user
      redirect_to groups_path, alert: "Only the group creator can perform this action."
      return
    end
    group.destroy
    redirect_to groups_path, notice: "Group and all memberships have been deleted."
  end

  # GET /groups/:id
  def show
    @group = @challenge.groups.includes(user_group_enrollments: { user: [ :avatar_attachment, :avatar_blob, :user_readings ] }).find(params[:id])
    @user_group = current_user.groups.where(challenge_id: @challenge.id).first
    @groups = @challenge.groups.order(:name)
                  .includes(user_group_enrollments: { user: [ :avatar_attachment, :avatar_blob ] })
                  .to_a

    # Calculate group statistics for challenge
    group_stats = GroupStatistics.new(@group)
    group_user_ids = @group.users.pluck(:id)
    current_date = Time.current.in_time_zone(@challenge.timezone).to_date

    # Total possible chapters = number of scheduled readings × number of members
    total_scheduled = @challenge.readings.where("scheduled_date <= ?", current_date).count
    total_possible = total_scheduled * group_user_ids.count

    # Total completed chapters across all group members
    total_completed = UserReading.where(user_id: group_user_ids)
                                  .joins(:reading)
                                  .where(readings: { challenge_id: @challenge.id })
                                  .where("readings.scheduled_date <= ?", current_date)
                                  .count

    # Total on-time chapters across all group members
    total_on_time = UserReading.where(user_id: group_user_ids)
                                .joins(:reading)
                                .where(readings: { challenge_id: @challenge.id })
                                .where("readings.scheduled_date <= ?", current_date)
                                .where("DATE(user_readings.completed_on) = readings.scheduled_date")
                                .count

    @group_stats = {
      completion_percentage: group_stats.completion_percentage,
      on_schedule_percentage: group_stats.on_schedule_percentage,
      total_completed: total_completed,
      total_possible: total_possible,
      total_on_time: total_on_time
    }

    # Find current sprint
    @current_sprint = @challenge.sprints.find_by("begin_date <= ? AND end_date >= ?", current_date, current_date)

    # Calculate sprint statistics if there's an active sprint
    if @current_sprint
      sprint_scheduled = @challenge.readings
                                   .where("scheduled_date >= ? AND scheduled_date <= ?", @current_sprint.begin_date, @current_sprint.end_date)
                                   .where("scheduled_date <= ?", current_date)
                                   .count
      sprint_possible = sprint_scheduled * group_user_ids.count

      sprint_completed = UserReading.where(user_id: group_user_ids)
                                    .joins(:reading)
                                    .where(readings: { challenge_id: @challenge.id })
                                    .where("readings.scheduled_date >= ? AND readings.scheduled_date <= ?", @current_sprint.begin_date, @current_sprint.end_date)
                                    .where("readings.scheduled_date <= ?", current_date)
                                    .count

      sprint_on_time = UserReading.where(user_id: group_user_ids)
                                  .joins(:reading)
                                  .where(readings: { challenge_id: @challenge.id })
                                  .where("readings.scheduled_date >= ? AND readings.scheduled_date <= ?", @current_sprint.begin_date, @current_sprint.end_date)
                                  .where("readings.scheduled_date <= ?", current_date)
                                  .where("DATE(user_readings.completed_on) = readings.scheduled_date")
                                  .count

      sprint_completion_percentage = sprint_possible.zero? ? 0 : (sprint_completed.to_f / sprint_possible * 100).round
      sprint_on_schedule_percentage = sprint_completed.zero? ? 0 : (sprint_on_time.to_f / sprint_completed * 100).round

      @sprint_stats = {
        completion_percentage: sprint_completion_percentage,
        on_schedule_percentage: sprint_on_schedule_percentage,
        total_completed: sprint_completed,
        total_possible: sprint_possible,
        total_on_time: sprint_on_time
      }
    end
  end

  # GET /groups/:id/edit
  def edit
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to group_path(@group), alert: "Only the group creator can edit this group."
      return
    end
    @members = @group.users.includes(:avatar_attachment, :avatar_blob).where.not(id: current_user.id)
  end

  # PATCH /groups/:id
  def update
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to group_path(@group), alert: "Only the group creator can edit this group."
      return
    end

    if @group.update(group_params)
      redirect_to group_path(@group), notice: "Group updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # GET /groups/:id/members/:member_id/confirm_remove
  def confirm_remove_member
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to group_path(@group), alert: t("groups.only_creator_can_edit")
      return
    end

    if params[:member_id].to_i == current_user.id
      redirect_to edit_group_path(@group), alert: "You cannot remove yourself. Use Leave Group instead."
      return
    end

    @member = @group.users.find(params[:member_id])
  end

  # DELETE /groups/:id/members/:member_id
  def remove_member
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to group_path(@group), alert: t("groups.only_creator_can_edit")
      return
    end

    if params[:member_id].to_i == current_user.id
      redirect_to edit_group_path(@group), alert: "You cannot remove yourself. Use Leave Group instead."
      return
    end

    member = @group.users.find(params[:member_id])
    enrollment = UserGroupEnrollment.find_by(user: member, group: @group)
    enrollment&.destroy

    redirect_to edit_group_path(@group), notice: t("groups.member_removed")
  end

  private

  def set_enrollment_and_challenge
    @enrollment = current_user.user_challenge_enrollments.last
    unless @enrollment
      redirect_to root_path, alert: "You must be enrolled in a challenge to view groups."
      return
    end
    @challenge = @enrollment.challenge
  end

  def group_params
    params.require(:group).permit(:name, :closed_to_new_members, :motto)
  end
end
