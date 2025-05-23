class GroupsController < ApplicationController
  before_action :require_login
  before_action :set_enrollment_and_challenge

  # GET /groups
  def index
    @groups = @challenge.groups.order(:name)
                  .includes(user_group_enrollments: { user: [ :avatar_attachment, :avatar_blob ] })
    @user_group = current_user.groups.where(challenge_id: @challenge.id).first
    if @user_group
      @groups = @groups.where.not(id: @user_group.id).to_a
      @groups.unshift(@user_group)
    else
      @groups = @groups.to_a
    end
  end

  # GET /groups/new
  def new
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to groups_path, alert: 'You are already in a group.'
      return
    end
    @group = @challenge.groups.new
  end

  # POST /groups
  def create
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to groups_path, alert: 'You are already in a group.'
      return
    end
    @group = @challenge.groups.new(group_params.merge(creator: current_user))
    if @group.save
      UserGroupEnrollment.create!(user: current_user, group: @group)
      redirect_to groups_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /groups/:id/confirm_destroy
  def confirm_destroy
    @group = @challenge.groups.find(params[:id])
    unless @group.creator == current_user
      redirect_to groups_path, alert: 'Only the group creator can perform this action.'
      return
    end
    @other_members = @group.user_group_enrollments.where.not(user_id: current_user.id)
    unless @other_members.exists?
      redirect_to groups_path, alert: 'No other members to remove.'
      return
    end
  end

  # POST /groups/leave
  def leave
    @user_group = current_user.groups.where(challenge_id: @challenge.id).first
    unless @user_group
      redirect_to groups_path, alert: 'You are not in a group.'
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
      redirect_to groups_path, alert: 'You are already in a group.'
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
      redirect_to groups_path, alert: 'Only the group creator can perform this action.'
      return
    end
    group.destroy
    redirect_to groups_path, notice: 'Group and all memberships have been deleted.'
  end

  private

  def set_enrollment_and_challenge
    @enrollment = current_user.user_challenge_enrollments.last
    unless @enrollment
      redirect_to root_path, alert: 'You must be enrolled in a challenge to view groups.'
      return
    end
    @challenge = @enrollment.challenge
  end

  def group_params
    params.require(:group).permit(:name)
  end
end 