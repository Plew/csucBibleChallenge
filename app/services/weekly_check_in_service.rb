# frozen_string_literal: true

class WeeklyCheckInService
  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  # Returns an array of hashes for N days centered around the selected date
  def days(selected_date = Time.current.in_time_zone(@challenge.timezone).to_date, num_days = 7)
    # Center the date range around the selected date, but don't go before challenge start or after today
    today = Time.current.in_time_zone(@challenge.timezone).to_date

    # Calculate ideal start and end dates (centered around selected_date)
    half_range = (num_days - 1) / 2
    ideal_start = selected_date - half_range.days
    ideal_end = selected_date + (num_days - 1 - half_range).days

    # Constrain to challenge boundaries and today
    actual_start = [ @challenge.start_date, ideal_start ].max
    actual_end = [ today, ideal_end ].min

    # Generate date range (may be less than num_days if at boundaries)
    dates = (actual_start..actual_end).to_a

    # If we have fewer than num_days, try to extend the range
    if dates.length < num_days
      # Try to extend backward first
      if actual_start > @challenge.start_date
        additional_days_needed = num_days - dates.length
        days_to_go_back = [ additional_days_needed, (actual_start - @challenge.start_date).to_i ].min
        actual_start = actual_start - days_to_go_back.days
      end

      # Then try to extend forward
      if dates.length < num_days && actual_end < today
        additional_days_needed = num_days - (actual_end - actual_start + 1)
        days_to_go_forward = [ additional_days_needed, (today - actual_end).to_i ].min
        actual_end = actual_end + days_to_go_forward.days
      end

      # Regenerate the date range
      dates = (actual_start..actual_end).to_a
    end

    # Map to the expected format
    dates.map do |date|
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
        day_of_week: date.strftime("%a"),
        day_of_month: date.day.to_s,
        month_day: date.strftime("%b %-d"),
        completed: completed,
        group_completion: group_completion,
        has_reading: reading.present?
      }
    end
  end
end
