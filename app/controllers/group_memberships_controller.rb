class GroupMembershipsController < ApplicationController
  before_action :set_group

  def create
    @group_membership = @group.group_memberships.build(user: current_user)
    if @group_membership.save
      redirect_to @group, notice: 'You have successfully joined the group.'
    else
      redirect_to @group, alert: 'Unable to join the group.'
    end
  end

  def destroy
    @group_membership = @group.group_memberships.find_by(user: current_user)
    if @group_membership&.destroy
      redirect_to @group, notice: 'You have left the group.'
    else
      redirect_to @group, alert: 'Unable to leave the group.'
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end
end