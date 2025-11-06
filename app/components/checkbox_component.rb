# frozen_string_literal: true

class CheckboxComponent < ViewComponent::Base
  def initialize(
    checked: false,
    disabled: false
    )
    @checked = checked
    @disabled = disabled
    super()
  end

  def disabled?
    @disabled
  end

  def checked?
    @checked
  end
end
