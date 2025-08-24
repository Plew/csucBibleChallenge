class GroupComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(group:, current_user:, user_group:)
    @group = group
    @current_user = current_user
    @user_group = user_group
  end

  private

  attr_reader :group, :current_user, :user_group

  def can_join_group?
    !user_group && !group.closed_to_new_members
  end

  def is_group_creator?
    group.creator == current_user
  end

  def is_user_in_this_group?
    user_group && group == user_group
  end

  def can_toggle_closed_status?
    is_group_creator? && is_user_in_this_group?
  end
end