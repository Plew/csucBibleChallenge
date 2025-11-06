class UserLastXComponentPreview < ViewComponent::Preview
  def all_checked_in
    render(UserLastXComponent.new(check_in_dates: random_dates_going_back_x_days(30), days_back: 30))
  end

  def none_checked_in
    render(UserLastXComponent.new(check_in_dates: [], days_back: 30))
  end

  private

  def random_dates_going_back_x_days(x)
    # going back x days, roughly half of the dates in that period should be in this list
    (0..x).to_a.map { |i| Date.today - i }.sample((x + 1) / 2)
  end
end
