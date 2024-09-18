class UserLastSevenComponent < ViewComponent::Base
  attr_reader :check_in_dates

  def initialize(check_in_dates:)
    @check_in_dates = check_in_dates
  end

  def last_seven_days
    # this method will look at Current.date and return an array of dates for the last 7 days
    # including today
    (0..6).map { |i| todays_date - i }
  end

  def todays_date
    Current.date || Date.today
  end

end