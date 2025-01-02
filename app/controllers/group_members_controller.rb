class GroupMembersController < ApplicationController
  before_action :set_group
  before_action :authorize_group_creator!

  def destroy
    user = User.find(params[:user_id])
    
    if @group.users.delete(user)
      flash[:notice] = "#{user.name} has been removed from the group."
    else
      flash[:alert] = "Unable to remove user from the group."
    end

    redirect_to edit_group_path(@group)
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def authorize_group_creator!
    unless @group.creator == current_user
      flash[:alert] = "Only the group creator can remove members."
      redirect_to edit_group_path(@group)
    end
  end
end 