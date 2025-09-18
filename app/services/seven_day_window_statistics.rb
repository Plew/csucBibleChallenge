# frozen_string_literal: true

class SevenDayWindowStatistics
  def self.call(challenge: nil)
    new(challenge).call
  end

  def initialize(challenge = nil)
    @challenge = challenge
  end

  def call
    users_with_readings = base_users_query

    users_with_readings.map do |user|
      seven_day_data = calculate_seven_day_data(user)
      {
        name: user.name,
        completion_percentage: seven_day_data[:completion_percentage],
        on_schedule_percentage: seven_day_data[:on_schedule_percentage],
        completed_days: seven_day_data[:completed_days],
        total_days: seven_day_data[:total_days]
      }
    end.sort_by { |data| [-data[:completion_percentage], -data[:on_schedule_percentage]] }
  end

  private

  def base_users_query
    User.joins(:user_readings, :challenges)
        .where.not(challenges: { timezone: nil })
        .tap { |query| query.where(challenges: { id: @challenge.id }) if @challenge }
        .distinct
  end

  def calculate_seven_day_data(user)
    challenges_to_calculate = @challenge ? [@challenge] : user.challenges.includes(:readings)
    
    total_scheduled_7_days = 0
    total_completed_7_days = 0
    total_on_schedule_7_days = 0

    challenges_to_calculate.each do |challenge|
      current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
      seven_days_ago = current_date_in_tz - 6.days # Including today = 7 days
      
      # Readings scheduled in the 7-day window
      scheduled_readings = challenge.readings
                                  .where(scheduled_date: seven_days_ago..current_date_in_tz)
      
      scheduled_count = scheduled_readings.count
      
      # Completed readings in the 7-day window
      completed_readings = user.user_readings
                              .joins(:reading)
                              .where(readings: { challenge_id: challenge.id })
                              .where(readings: { scheduled_date: seven_days_ago..current_date_in_tz })
      
      completed_count = completed_readings.count
      
      # On-schedule readings (completed on or before scheduled date)
      on_schedule_count = completed_readings
                         .where('date(user_readings.created_at) <= readings.scheduled_date')
                         .count
      
      total_scheduled_7_days += scheduled_count
      total_completed_7_days += completed_count
      total_on_schedule_7_days += on_schedule_count
    end

    completion_percentage = if total_scheduled_7_days.zero?
                           0.0
                         else
                           (total_completed_7_days.to_f / total_scheduled_7_days * 100).round(1)
                         end

    on_schedule_percentage = if total_completed_7_days.zero?
                            0.0
                          else
                            (total_on_schedule_7_days.to_f / total_completed_7_days * 100).round(1)
                          end

    {
      completion_percentage: completion_percentage,
      on_schedule_percentage: on_schedule_percentage,
      completed_days: total_completed_7_days,
      total_days: total_scheduled_7_days
    }
  end
end