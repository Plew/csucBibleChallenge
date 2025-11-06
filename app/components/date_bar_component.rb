# frozen_string_literal: true

class DateBarComponent < ViewComponent::Base
  def initialize(selected_date: nil, mobile: false, days: nil)
    @selected_date = selected_date || Date.current
    @mobile = mobile
    @days = days || generate_week_days(@selected_date)
  end

  private

  def generate_week_days(selected_date)
    # Find the Monday of the week containing the selected date
    start_of_week = selected_date.beginning_of_week(:monday)

    # Generate 7 days starting from Monday
    7.times.map do |i|
      date = start_of_week + i.days
      {
        date: date,
        day_of_week: date.strftime("%a"),
        day_of_month: date.day.to_s,
        month_day: date.strftime("%b %-d"),
        completed: false, # This should be set by the calling code based on actual data
        group_completion: 0, # This should be set by the calling code based on actual data
        has_reading: true # This should be set by the calling code based on actual data
      }
    end
  end

  def previous_week_date
    @selected_date - 7.days
  end

  def next_week_date
    @selected_date + 7.days
  end

  def current_week_monday
    @selected_date.beginning_of_week(:monday)
  end
end
