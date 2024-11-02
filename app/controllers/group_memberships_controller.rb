class GroupMembershipsController < ApplicationController

  def new
  end

  def create
    group = Group.find_by(key: params[:key].upcase)

    if group
      group_membership = group.group_memberships.build(user: current_user)
      group_membership.save
      redirect_to groups_path, notice: 'You have joined this group.'
    else
      redirect_to new_group_membership_path, notice: 'No group exists with that key.'
    end
  end

  def destroy
    group_membership = GroupMembership.find_by(user: current_user, group_id: params[:group_id])
    group_membership&.destroy
    redirect_to groups_path
  end

end