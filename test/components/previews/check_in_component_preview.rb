# frozen_string_literal: true

class CheckInComponentPreview < ViewComponent::Preview
  def unchecked
    render(CheckInComponent.new(shown_date: '2024-01-01'))
  end

  def checked
    render(CheckInComponent.new(shown_date: '2024-01-01', checked: true))
  end

end