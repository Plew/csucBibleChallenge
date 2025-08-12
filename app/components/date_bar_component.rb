# frozen_string_literal: true

class DateBarComponent < ViewComponent::Base
  # days: array of hashes with keys :date, :day_of_week, :day_of_month, :month_day, :completed, :group_completion, :has_reading
  def initialize(days:, selected_date: nil, mobile: false)
    @days = days
    @selected_date = selected_date
    @mobile = mobile
  end
  
  private
  
  def should_use_scrolling?
    # Always mobile-first approach: enable scrolling only if we have more than 7 days
    # But since we limit to 7 days in the service, this should rarely be true
    # This is here as a safety net in case the service returns more days
    @days.length > 7
  end
end