class UserLastSevenComponentPreview < ViewComponent::Preview
  def default
    render(UserLastSevenComponent.new(check_ins: [true, false, true, true, false, true, false]))
  end

  def all_checked_in
    render(UserLastSevenComponent.new(check_ins: [true] * 7))
  end

  def none_checked_in
    render(UserLastSevenComponent.new(check_ins: [false] * 7))
  end

  def partial_week
    render(UserLastSevenComponent.new(check_ins: [true, false, true]))
  end
end