class CheckboxComponent < ViewComponent::Base
  def initialize(
    shown_date:,
    checked: false,
    disabled: true
    )
    @checked = checked
    @shown_date = shown_date
    @disabled = disabled
  end

  def previous_date
    puts "Previous date: #{@shown_date}"
    date = Date.parse(@shown_date)
    (date - 1).strftime('%Y-%m-%d')
  end

  def next_date
    date = Date.parse(@shown_date)
    (date + 1).strftime('%Y-%m-%d')
  end
end