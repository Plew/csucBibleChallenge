class GroupsController < ApplicationController
  before_action :require_login
  before_action :set_enrollment_and_challenge

  # GET /groups
  def index
    @groups = @challenge.groups.order(:name)
    @user_group = @enrollment.group
    if @user_group
      @groups = [@user_group] + @groups.where.not(id: @user_group.id)
    end
  end

  # POST /groups/:id/join
  def join
    group = @challenge.groups.find(params[:id])
    if @enrollment.group_id.present?
      redirect_to groups_path, alert: 'You are already in a group.'
      return
    end
    @enrollment.update!(group: group)
    redirect_to groups_path, notice: "You have joined the group '#{group.name}'."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to groups_path, alert: e.record.errors.full_messages.to_sentence
  end

  # POST /groups/leave
  def leave
    if @enrollment.group_id.nil?
      redirect_to groups_path, alert: 'You are not in a group.'
      return
    end
    @enrollment.update!(group_id: nil)
    redirect_to groups_path, notice: 'You have left your group.'
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
end 