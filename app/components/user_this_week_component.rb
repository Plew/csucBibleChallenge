# frozen_string_literal: true

class UserThisWeekComponent < ViewComponent::Base

  def initialize(check_in_dates: [], todays_date: Current.date || Current.system_date)
    @check_in_dates = check_in_dates
    @todays_date = todays_date
  end

  private

  def this_weeks_start_date
    # this method will look at todays_date and return the date for the start of the week
    # and the start of the week must be a sunday
    @todays_date.beginning_of_week(:sunday)
  end

  def this_weeks_days
    # the days of the week are from sunday to saturday
    (this_weeks_start_date..this_weeks_start_date + 6)
  end
end