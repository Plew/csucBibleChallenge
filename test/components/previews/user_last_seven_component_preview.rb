class UserLastSevenComponentPreview < ViewComponent::Preview
#   def default
#     render(UserLastSevenComponent.new(check_ins: [true, false, true, true, false, true, false]))
#   end

  def all_checked_in
    render(UserLastSevenComponent.new(check_in_dates: all_checked))
  end

  def none_checked_in
    render(UserLastSevenComponent.new(check_in_dates: []))
  end

#   def partial_week
#     render(UserLastSevenComponent.new(check_ins: [true, false, true]))
#   end

  private

  def all_checked
    7.times.map do |i|
      [Date.today - i, true]
    end
  end

end
