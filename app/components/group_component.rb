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

  def has_read_today?(user)
    return false unless todays_reading

    user.user_readings.exists?(
      reading_id: todays_reading.id,
      completed_on: today_in_challenge_timezone
    )
  end

  def todays_reading
    @todays_reading ||= group.challenge.readings.find_by(
      scheduled_date: today_in_challenge_timezone
    )
  end

  def today_in_challenge_timezone
    @today_in_challenge_timezone ||= Time.use_zone(group.challenge.timezone) { Date.current }
  end
end