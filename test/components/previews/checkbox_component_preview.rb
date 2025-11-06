# frozen_string_literal: true

class CheckboxComponentPreview < ViewComponent::Preview
  def unchecked_enabled
    render(CheckboxComponent.new(checked: false, disabled: false))
  end

  def natnael
    render(CheckboxComponent.new(checked: false, disabled: false))
  end

  def checked_enabled
    render(CheckboxComponent.new(checked: true, disabled: false))
  end

  def unchecked_disabled
    render(CheckboxComponent.new(checked: false, disabled: true))
  end

  def checked_disabled
    render(CheckboxComponent.new(checked: true, disabled: true))
  end
end
