# frozen_string_literal: true

class ReadingHistoryGraphComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(total_days:, completed_days: [], start_date: nil)
    @total_days = total_days
    @completed_days = completed_days.to_set
    @start_date = start_date || Date.today
  end

  def days
    (0...@total_days).map do |day_number|
      {
        number: day_number,
        date: @start_date + day_number.days,
        completed: @completed_days.include?(day_number)
      }
    end
  end

  def day_class(day)
    base_classes = "w-3 h-3 rounded-sm transition-colors duration-200"

    if day[:completed]
      "#{base_classes} bg-success"
    else
      "#{base_classes} bg-base-300"
    end
  end

  def tooltip_text(day)
    status = day[:completed] ? t('common.completed') : t('common.not_completed')
    "#{t('common.day')} #{day[:number] + 1}: #{day[:date].strftime('%b %d, %Y')} - #{status}"
  end
end
