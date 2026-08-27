class GroupInvitationsController < ApplicationController
  before_action :set_group_by_token

  # GET /groups/:token/join
  def show
    session[:group_invitation_token] = @group.token
    @challenge = @group.challenge
    @is_enrolled_in_group = logged_in? && current_user.groups.include?(@group)
    @is_enrolled_in_challenge = logged_in? && current_user.challenges.include?(@challenge)
    @member_count = @group.users.count
    @total_chapters = @challenge.readings.count
  end

  # POST /groups/:token/accept
  def accept
    unless logged_in?
      session[:group_invitation_token] = @group.token
      redirect_to new_user_session_path, notice: "Please sign in to join #{@group.name}."
      return
    end

    # Auto-enroll in challenge if not yet enrolled
    unless current_user.challenges.include?(@group.challenge)
      challenge_enrollment = @group.challenge.user_challenge_enrollments.new(user: current_user)
      unless challenge_enrollment.save
        redirect_to group_invitation_path(@group.token), alert: "Could not join challenge: #{challenge_enrollment.errors.full_messages.to_sentence}"
        return
      end
    end

    set_active_challenge(@group.challenge)

    # Check if already in this group
    if current_user.groups.include?(@group)
      redirect_to group_path(@group), notice: "You are already a member of #{@group.name}!"
      return
    end

    # Enroll in group
    group_enrollment = @group.user_group_enrollments.new(user: current_user)
    if group_enrollment.save
      session.delete(:group_invitation_token)
      redirect_to group_path(@group), notice: "Successfully joined #{@group.name}!"
    else
      redirect_to group_invitation_path(@group.token), alert: "Could not join group: #{group_enrollment.errors.full_messages.to_sentence}"
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
