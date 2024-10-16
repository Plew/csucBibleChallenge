# frozen_string_literal: true

class CheckInComponentPreview < ViewComponent::Preview
  def unchecked
    render(CheckInComponent.new(active_date: Date.today, checked: false))
  end

  def checked
    render(CheckInComponent.new(active_date: Date.today, checked: true))
  end

  def disabled_day
    render(CheckInComponent.new(active_date: Date.yesterday, checked: false))
  end
end