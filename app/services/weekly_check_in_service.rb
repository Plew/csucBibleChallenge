# frozen_string_literal: true

class WeeklyCheckInService
  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  # Returns an array of hashes for the last 7 days (including today)
  def days(today = Time.current.in_time_zone(@challenge.timezone).to_date)
    start_date = today - 6.days
    (0..6).map do |i|
      date = start_date + i.days
      reading = @challenge.readings.find_by(scheduled_date: date)
      completed = reading && @user.user_readings.exists?(reading_id: reading.id)
      group_completion = 0
      if reading
        user_group = @user.groups.find_by(challenge_id: @challenge.id)
        if user_group
          group_stats = GroupStatistics.new(user_group)
          group_completion = group_stats.check_in_percentage(date).to_i
        end
      end
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        completed: completed,
        group_completion: group_completion,
        has_reading: reading.present?
      }
    end
  end
end 