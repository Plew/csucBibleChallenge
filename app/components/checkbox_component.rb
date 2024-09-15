class CheckboxComponent < ViewComponent::Base
  def initialize(
    checked: false,
    disabled: false
    )
    @checked = checked
    @disabled = disabled
  end

  def displayed_image
    if @checked
      'checkbox_checked.png'
    else
      'checkbox_empty.png'
    end
  end

  def disabled?
    @disabled
  end
end