class GroupInvitationsController < ApplicationController
  before_action :set_group_by_token

  # GET /groups/:token/join
  def show
    if logged_in?
      # Check if user is already enrolled in the challenge
      unless current_user.challenges.include?(@group.challenge)
        # Check if user is in any other challenge (one challenge at a time rule)
        if current_user.challenges.any?
          redirect_to root_path, alert: "You are already enrolled in a different challenge. Leave your current challenge to join this one."
          return
        end

        # Enroll the user in the challenge first
        challenge_enrollment = @group.challenge.user_challenge_enrollments.new(user: current_user)
        unless challenge_enrollment.save
          redirect_to root_path, alert: "Could not join challenge: #{challenge_enrollment.errors.full_messages.to_sentence}"
          return
        end
      end

      # Check if user is already in this group
      if current_user.groups.include?(@group)
        redirect_to group_path(@group), notice: "You are already a member of #{@group.name}!"
        return
      end

      # Enroll the user in the group
      group_enrollment = @group.user_group_enrollments.new(user: current_user)
      if group_enrollment.save
        redirect_to group_path(@group), notice: "Successfully joined #{@group.name}!"
      else
        redirect_to root_path, alert: "Could not join group: #{group_enrollment.errors.full_messages.to_sentence}"
      end
    else
      # Store token and redirect to group show page for non-logged-in users
      session[:group_invitation_token] = @group.token
      redirect_to group_path(@group)
    end
  end

  private

  def set_group_by_token
    @group = Group.find_by(token: params[:token])
    unless @group
      redirect_to root_path, alert: "Invalid group invitation link."
    end
  end
end
