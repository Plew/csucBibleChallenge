# frozen_string_literal: true

class CheckboxComponentPreview < ViewComponent::Preview

  def default
    render(CheckboxComponent.new(shown_date: '2024-01-01'))
  end

  def checked
    render(CheckboxComponent.new(checked: true))
  end

  def with_name_and_value
    render(CheckboxComponent.new(name: "agreement", value: "accepted"))
  end

  def without_label
    render(CheckboxComponent.new(name: "option", value: "1"))
  end
end