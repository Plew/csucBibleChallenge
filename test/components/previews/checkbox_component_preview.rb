# frozen_string_literal: true

class CheckboxComponentPreview < ViewComponent::Preview

  def unchecked
    render(CheckboxComponent.new()
  end

  def checked
    render(CheckboxComponent.new(shown_date: '2024-01-01', checked: true))
  end

end