class GroupMembershipsController < ApplicationController

  def new
  end

  def create
    @group = Group.find_by(key: params[:key])
    @group_membership = @group.group_memberships.build(user: current_user)
    @group_membership.save
    # redirect_to @group
    redirect_to groups_path
  end

  def destroy
    @group_membership = @group.group_memberships.find_by(user: current_user)
    if @group_membership&.destroy
      redirect_to @group, notice: 'You have left the group.'
    else
      redirect_to @group, alert: 'Unable to leave the group.'
    end
  end

end