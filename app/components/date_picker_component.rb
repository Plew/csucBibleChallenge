# frozen_string_literal: true

class DatePickerComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(selected_date:, challenge:, user:)
    @selected_date = selected_date
    @challenge = challenge
    @user = user
    @display_month = selected_date.beginning_of_month
  end

  private

  attr_reader :selected_date, :challenge, :user, :display_month

  def month_title
    display_month.strftime("%B %Y")
  end

  def prev_month
    (display_month - 1.month).strftime("%Y-%m-%d")
  end

  def next_month
    (display_month + 1.month).strftime("%Y-%m-%d")
  end

  def calendar_weeks
    # Get the first day of the month and pad to start from Monday
    first_of_month = display_month.beginning_of_month
    last_of_month = display_month.end_of_month

    # Start from the Monday of the week containing the first day
    calendar_start = first_of_month.beginning_of_week(:monday)
    # End on Sunday of the week containing the last day
    calendar_end = last_of_month.end_of_week(:monday)

    # Build weeks array
    weeks = []
    current_date = calendar_start

    while current_date <= calendar_end
      week = []
      7.times do
        week << build_day_data(current_date)
        current_date += 1.day
      end
      weeks << week
    end

    weeks
  end

  def build_day_data(date)
    in_month = date.month == display_month.month
    day_readings = in_month ? challenge.readings.where(scheduled_date: date) : []
    has_reading = day_readings.any?
    completed = has_reading && day_readings.all? { |r| user.user_readings.exists?(reading_id: r.id) }
    partial_completed = has_reading && !completed && day_readings.any? { |r| user.user_readings.exists?(reading_id: r.id) }
    is_selected = date == selected_date

    {
      date: date,
      day: date.day,
      in_month: in_month,
      has_reading: has_reading,
      completed: completed,
      partial_completed: partial_completed,
      is_selected: is_selected
    }
  end

  def day_classes(day)
    base = "w-8 h-8 flex items-center justify-center text-xs rounded-sm transition-colors"

    return "#{base} text-base-300" unless day[:in_month]

    if day[:completed]
      # Completed: green background
      "#{base} bg-success text-success-content cursor-pointer hover:opacity-80"
    elsif day[:partial_completed]
      # Partially completed: warning background
      "#{base} bg-warning text-warning-content cursor-pointer hover:opacity-80"
    elsif day[:has_reading]
      # Has reading but not completed: show date number, clickable
      if day[:is_selected]
        "#{base} bg-primary text-primary-content cursor-pointer"
      else
        "#{base} bg-base-200 text-base-content cursor-pointer hover:bg-base-300"
      end
    else
      # No reading scheduled
      "#{base} text-base-content/30"
    end
  end

  def day_content(day)
    return "" unless day[:in_month]

    if day[:completed]
      # Show checkmark for completed
      ""
    else
      # Show day number for incomplete or no reading
      day[:day].to_s
    end
  end

  def day_link(day)
    return nil unless day[:in_month] && day[:has_reading]

    "/reading?date=#{day[:date]}"
  end

  def weekday_names
    %w[M T W T F S S]
  end
end
