# frozen_string_literal: true

class GroupStatistics
  attr_reader :group

  def initialize(group)
    @group = group
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
    (completed_count.to_f / group_user_ids.size * 100).round(2)
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
        max_streak = [max_streak, current_streak].max
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
    total_readings = challenge.readings.where('scheduled_date <= ?', Date.current).count
    return 0 if total_readings.zero?
    percentages = group_user_ids.map do |user_id|
      completed = UserReading.where(user_id: user_id).joins(:reading).where(readings: { challenge_id: challenge.id }).where('readings.scheduled_date <= ?', Date.current).count
      (completed.to_f / total_readings * 100)
    end
    (percentages.sum / group_user_ids.size).round
  end
end 