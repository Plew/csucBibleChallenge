# frozen_string_literal: true

class GroupStatistics
  attr_reader :group, :date_range

  def initialize(group, date_range = nil)
    @group = group
    @date_range = date_range
  end

  def group_size
    group.users.count
  end

  def last_membership_change_date
    group.user_group_enrollments.maximum(:updated_at)&.to_date
  end

  # For a given date, percentage of group members who completed the reading
  def check_in_percentage(date)
    challenge = group.challenge
    reading = challenge.readings.find_by(scheduled_date: date)
    return 0 unless reading
    group_user_ids = group.users.pluck(:id)
    completed_count = UserReading.where(user_id: group_user_ids, reading_id: reading.id).count
    return 0 if group_user_ids.empty?
    return 100 if completed_count == group_user_ids.size

    (completed_count.to_f / group_user_ids.size * 100).floor
  end

  # Longest streak where every member completed the reading
  def longest_group_streak
    challenge = group.challenge
    group_user_ids = group.users.pluck(:id)
    dates = challenge.readings.order(:scheduled_date).pluck(:scheduled_date)
    max_streak = 0
    current_streak = 0
    dates.each do |date|
      reading = challenge.readings.find_by(scheduled_date: date)
      next unless reading
      completed_count = UserReading.where(user_id: group_user_ids, reading_id: reading.id).count
      if completed_count == group_user_ids.size && group_user_ids.size > 0
        current_streak += 1
        max_streak = [ max_streak, current_streak ].max
      else
        current_streak = 0
      end
    end
    max_streak
  end

  def total_chapters_read
    group_user_ids = group.users.pluck(:id)
    UserReading.where(user_id: group_user_ids).count
  end

  def completion_percentage
    group_user_ids = group.users.pluck(:id)
    challenge = group.challenge
    return 0 if group_user_ids.empty?

    readings_query = challenge.readings.where("scheduled_date <= ?", Date.current)
    readings_query = readings_query.where(scheduled_date: date_range) if date_range
    total_readings = readings_query.count
    return 0 if total_readings.zero?

    percentages = group_user_ids.map do |user_id|
      completed_query = UserReading.where(user_id: user_id).joins(:reading).where(readings: { challenge_id: challenge.id }).where("readings.scheduled_date <= ?", Date.current)
      completed_query = completed_query.where(readings: { scheduled_date: date_range }) if date_range
      completed = completed_query.count
      (completed.to_f / total_readings * 100)
    end
    (percentages.sum / group_user_ids.size).floor
  end

  def on_schedule_percentage
    group_users = group.users
    challenge = group.challenge
    return 0 if group_users.empty?

    # Calculate average on-schedule percentage across all group members
    if date_range
      # Use individual calculations when date_range is present
      percentages = group_users.map do |user|
        OnScheduleStatistic.new(user, challenge, date_range).percentage
      end
      (percentages.sum / group_users.size).floor
    else
      # Use batch query when no date_range (more efficient)
      user_ids = group_users.pluck(:id)
      percentages_by_user = OnScheduleStatistic.batch_percentages(user_ids, challenge)
      (percentages_by_user.values.sum / group_users.size).floor
    end
  end
end
