class UserLastXComponent < ViewComponent::Base
  attr_reader :check_in_dates

  def initialize(check_in_dates:, days_back: 7)
    @check_in_dates = check_in_dates
    @days_back = days_back
  end

  def last_x_days
    (0..@days_back - 1).map { |i| todays_date - i }
  end

  def todays_date
    Current.current_date || Date.today
  end

end