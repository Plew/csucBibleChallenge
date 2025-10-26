# frozen_string_literal: true

class ReadingHistoryGraphComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(total_days:, completed_days: [], start_date: nil, current_day: nil)
    @total_days = total_days
    # completed_days is now an array of hashes: [{day: 0, on_time: true}, ...]
    # Convert to a hash for quick lookup: {day_number => on_time_boolean}
    @completed_days_map = completed_days.each_with_object({}) do |day_info, hash|
      hash[day_info[:day]] = day_info[:on_time]
    end
    @start_date = start_date || Date.today
    @current_day = current_day
  end

  def days
    (0...@total_days).map do |day_number|
      {
        number: day_number,
        date: @start_date + day_number.days,
        completed: @completed_days_map.key?(day_number),
        on_time: @completed_days_map[day_number],
        is_current: @current_day == day_number
      }
    end
  end

  def day_class(day)
    base_classes = "w-3 h-3 rounded-sm transition-colors duration-200 relative cursor-pointer"

    if day[:completed]
      if day[:on_time]
        # Completed on time: solid green
        "#{base_classes} bg-success"
      else
        # Completed late: outlined - class without color
        "#{base_classes} border-2 bg-transparent"
      end
    else
      # Not completed: gray
      "#{base_classes} bg-base-300"
    end
  end

  def day_style(day)
    # For late readings, set border color to match the success color exactly
    if day[:completed] && !day[:on_time]
      # Get the CSS variable for success color from DaisyUI
      "border-color: oklch(var(--su));"
    end
  end

  def tooltip_text(day)
    if day[:completed]
      status = day[:on_time] ? t('common.completed_on_time') : t('common.completed_late')
    else
      status = t('common.not_completed')
    end
    "#{t('common.day')} #{day[:number] + 1}: #{day[:date].strftime('%b %d, %Y')} - #{status}"
  end
end
