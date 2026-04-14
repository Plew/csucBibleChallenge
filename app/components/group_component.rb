class GroupComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(group:, current_user:, user_group:, group_stats: nil, sprint_stats: nil, current_sprint: nil, simulate_9pm: false)
    @group = group
    @current_user = current_user
    @user_group = user_group
    @group_stats = group_stats
    @sprint_stats = sprint_stats
    @current_sprint = current_sprint
    @simulate_9pm = simulate_9pm
  end

  private

  attr_reader :group, :current_user, :user_group, :group_stats, :sprint_stats, :current_sprint, :simulate_9pm

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

  def challenge_start_date
    @challenge_start_date ||= group.challenge.start_date
  end

  def total_challenge_days
    @total_challenge_days ||= group.challenge.readings.count
  end

  def completed_days_for_user(user)
    # Get all readings for the challenge with their scheduled dates
    challenge_readings = group.challenge.readings.select(:id, :scheduled_date).index_by(&:id)

    # Get completed readings with their completion dates
    completed_readings = user.user_readings
      .where(reading_id: challenge_readings.keys)
      .pluck(:reading_id, :completed_on)

    # For each completed reading, determine day number and if it was on time
    # "On time" means completed_on matches the scheduled_date (both in challenge timezone)
    completed_readings.map do |reading_id, completed_on|
      reading = challenge_readings[reading_id]
      day_number = (reading.scheduled_date - challenge_start_date).to_i

      # Both dates should already be Date objects, so we can compare directly
      # The scheduled_date is stored as a Date, and completed_on is stored as a Date
      on_time = (completed_on == reading.scheduled_date)

      { day: day_number, on_time: on_time }
    end
  end

  def current_day_number
    # Calculate the day number based on today's date in the challenge timezone
    (today_in_challenge_timezone - challenge_start_date).to_i
  end

  def has_active_sprint?
    current_sprint.present? && sprint_stats.present?
  end

  def sprint_start_date
    @sprint_start_date ||= current_sprint&.begin_date
  end

  def total_sprint_days
    return 0 unless current_sprint
    challenge_readings = group.challenge.readings
      .where("scheduled_date >= ? AND scheduled_date <= ?", current_sprint.begin_date, current_sprint.end_date)
      .count
  end

  def completed_days_for_user_sprint(user)
    return [] unless current_sprint

    # Get readings within the sprint date range
    sprint_readings = group.challenge.readings
      .where("scheduled_date >= ? AND scheduled_date <= ?", current_sprint.begin_date, current_sprint.end_date)
      .select(:id, :scheduled_date)
      .index_by(&:id)

    # Get completed readings with their completion dates
    completed_readings = user.user_readings
      .where(reading_id: sprint_readings.keys)
      .pluck(:reading_id, :completed_on)

    # For each completed reading, determine day number (relative to sprint start) and if it was on time
    completed_readings.map do |reading_id, completed_on|
      reading = sprint_readings[reading_id]
      day_number = (reading.scheduled_date - sprint_start_date).to_i
      on_time = (completed_on == reading.scheduled_date)

      { day: day_number, on_time: on_time }
    end
  end

  def current_sprint_day_number
    return 0 unless current_sprint
    (today_in_challenge_timezone - sprint_start_date).to_i
  end

  def after_9pm?
    return true if simulate_9pm

    now = Time.current.in_time_zone(group.challenge.timezone)
    now.hour >= 21
  end

  def pokeable?(user)
    return false if user == current_user
    return false unless is_user_in_this_group?
    return false if has_read_today?(user)
    return false unless after_9pm?
    return false unless user_ids_with_push_subscriptions.include?(user.id)
    true
  end

  def already_poked_today?(user)
    poked_today_user_ids.include?(user.id)
  end

  def user_ids_with_push_subscriptions
    @user_ids_with_push_subscriptions ||= begin
      member_ids = group.users.pluck(:id)
      PushSubscription.where(user_id: member_ids).distinct.pluck(:user_id).to_set
    end
  end

  def poked_today_user_ids
    @poked_today_user_ids ||= Poke.where(
      poker: current_user,
      challenge: group.challenge,
      poked_on: today_in_challenge_timezone
    ).pluck(:pokee_id).to_set
  end
end
