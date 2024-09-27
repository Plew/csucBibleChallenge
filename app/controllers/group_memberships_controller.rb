class GroupMembershipsController < ApplicationController
  before_action :set_group

  def new
    @group = Group.find(params[:group_id])
    @group_membership = GroupMembership.new
  end

  def create
    @group = Group.find(params[:group_id])
    @group_membership = @group.group_memberships.build(user: current_user)

    if params[:key] == @group.key
      if @group_membership.save
        redirect_to @group, notice: 'You have successfully joined the group.'
      else
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Invalid key. Please try again.'
      render :new, status: :unprocessable_entity
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