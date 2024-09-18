class UserThisWeekComponentPreview < ViewComponent::Preview

  def all_checked_in
    render(UserThisWeekComponent.new(check_in_dates: all_checked, todays_date: Date.today))
  end

  def none_checked_in
    # why is the application controller version of this not working
    render(UserThisWeekComponent.new(check_in_dates: [], todays_date: Date.today))
  end

  private

  def all_checked
    7.times.map { |i| Date.today - i }
  end
end