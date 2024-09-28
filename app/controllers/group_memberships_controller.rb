class GroupMembershipsController < ApplicationController

  def new
  end

  def create
    group = Group.find_by(key: params[:key])
    group_membership = group.group_memberships.build(user: current_user)
    group_membership.save
    # redirect_to @group
    redirect_to groups_path
  end

  def destroy
    group_membership = GroupMembership.find_by(user: current_user, group_id: params[:group_id])
    group_membership&.destroy
    redirect_to groups_path
  end

end