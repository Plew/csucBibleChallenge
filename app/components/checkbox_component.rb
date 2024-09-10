class CheckboxComponent < ViewComponent::Base
  def initialize(checked: false, name: nil, value: nil, label: nil)
    @checked = checked
    @name = name
    @value = value
    @label = label
  end
end