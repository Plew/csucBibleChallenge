class ChallengeGroupsController < ApplicationController
  before_action :require_login
  before_action :set_challenge

  # POST /challenges/:challenge_id/groups
  def create
    # Check if user is enrolled in the challenge
    unless current_user.user_challenge_enrollments.exists?(challenge: @challenge)
      redirect_to challenge_path(@challenge), alert: "You must be enrolled in the challenge to create a group."
      return
    end

    # Check if user is already in a group for this challenge
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to challenge_path(@challenge), alert: "You are already in a group for this challenge."
      return
    end

    @group = @challenge.groups.new(group_params.merge(creator: current_user))

    if @group.save
      UserGroupEnrollment.create!(user: current_user, group: @group)
      redirect_to challenge_path(@challenge), notice: "Group created successfully!"
    else
      redirect_to challenge_path(@challenge), alert: @group.errors.full_messages.to_sentence
    end
  end

  # POST /challenges/:challenge_id/groups/:id/join
  def join
    group = @challenge.groups.find(params[:id])

    # Check if user is enrolled in the challenge
    unless current_user.user_challenge_enrollments.exists?(challenge: @challenge)
      redirect_to challenge_path(@challenge), alert: "You must be enrolled in the challenge to join a group."
      return
    end

    # Check if user is already in a group for this challenge
    if current_user.groups.where(challenge_id: @challenge.id).exists?
      redirect_to challenge_path(@challenge), alert: "You are already in a group for this challenge."
      return
    end

    # Check if group is closed to new members
    if group.closed_to_new_members
      redirect_to challenge_path(@challenge), alert: "This group is closed to new members."
      return
    end

    UserGroupEnrollment.create!(user: current_user, group: group)
    redirect_to challenge_path(@challenge), notice: "You have joined #{group.name}!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to challenge_path(@challenge), alert: e.record.errors.full_messages.to_sentence
  end

  # POST /challenges/:challenge_id/groups/:id/leave
  def leave
    group = @challenge.groups.find(params[:id])

    # Check if user is in the group
    enrollment = UserGroupEnrollment.find_by(user: current_user, group: group)
    unless enrollment
      redirect_to challenge_path(@challenge), alert: "You are not in this group."
      return
    end

    # If user is the creator and there are other members, handle differently
    if group.creator == current_user
      other_members = group.user_group_enrollments.where.not(user_id: current_user.id)
      if other_members.exists?
        # Delete the entire group
        group.destroy
        redirect_to challenge_path(@challenge), notice: "Group deleted and all members removed."
        return
      else
        # Just delete the group (only member is the creator)
        group.destroy
        redirect_to challenge_path(@challenge), notice: "Group deleted."
        return
      end
    end

    # Regular member leaving
    enrollment.destroy
    redirect_to challenge_path(@challenge), notice: "You have left the group."
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def group_params
    params.require(:group).permit(:name, :motto)
  end
end
