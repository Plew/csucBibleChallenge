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
    return [] unless @challenge

    today = Time.current.in_time_zone(@challenge.timezone).to_date

    # Single query: today's reading
    todays_reading = @challenge.readings.find_by(scheduled_date: today)

    # Single query: load all groups with user counts
    groups = @challenge.groups.includes(:users)
    return [] if groups.empty?

    if todays_reading
      # Single query: batch get all completions for today's reading
      completed_user_ids = UserReading
        .where(reading_id: todays_reading.id)
        .pluck(:user_id)
        .to_set
    else
      completed_user_ids = Set.new
    end

    groups.map do |group|
      group_user_ids = group.users.map(&:id)
      group_size = group_user_ids.length
      next if group_size.zero?

      today_completed = group_user_ids.count { |uid| completed_user_ids.include?(uid) }
      today_pct = (today_completed.to_f / group_size * 100)

      {
        group: group,
        completion_percentage: 0,
        on_schedule_percentage: 0,
        group_size: group_size,
        total_chapters_read: 0,
        today_check_in_percentage: today_pct,
        today_members_completed: today_completed,
        today_total_members: group_size
      }
    end.compact
       .sort_by { |d| -d[:today_check_in_percentage] }
       .first(20)
  end
end
