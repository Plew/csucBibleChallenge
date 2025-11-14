# frozen_string_literal: true

class TopGroupsStatistics
  def self.call(challenge: nil, date_range: nil)
    new(challenge, date_range).call
  end

  def initialize(challenge = nil, date_range = nil)
    @challenge = challenge
    @date_range = date_range
  end

  def call
    groups_scope = @challenge ? @challenge.groups : Group.joins(:challenge)

    # Get today's date in the challenge timezone
    today = @challenge ? Time.current.in_time_zone(@challenge.timezone).to_date : Date.current

    # Eager load users with their avatars for expandable group lists
    groups_scope.includes(users: { avatar_attachment: :blob }, challenge: :readings).map do |group|
      group_stats = GroupStatistics.new(group, @date_range)
      {
        group: group,
        completion_percentage: group_stats.completion_percentage,
        on_schedule_percentage: group_stats.on_schedule_percentage,
        group_size: group_stats.group_size,
        total_chapters_read: group_stats.total_chapters_read,
        today_check_in_percentage: group_stats.check_in_percentage(today),
        today_members_completed: calculate_today_members_completed(group, today),
        today_total_members: group_stats.group_size
      }
    end.sort_by { |group_data| -group_data[:completion_percentage] }
       .first(20)
  end

  private

  attr_reader :challenge

  def calculate_today_members_completed(group, date)
    reading = group.challenge.readings.find_by(scheduled_date: date)
    return 0 unless reading

    group_user_ids = group.users.pluck(:id)
    UserReading.where(user_id: group_user_ids, reading_id: reading.id).count
  end
end
