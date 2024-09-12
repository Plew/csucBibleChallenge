class CheckboxComponent < ViewComponent::Base
  def initialize(
    shown_date:,
    current_date:,
    checked: false,
    disabled: true
    )
    @checked = checked
    @shown_date = shown_date
    @current_date = current_date
    @disabled = disabled
  end

  def previous_date
    date = Date.parse(@shown_date)
    (date - 1).strftime('%Y-%m-%d')
  end

  def next_date
    date = Date.parse(@shown_date)
    (date + 1).strftime('%Y-%m-%d')
  end

  def hide_next?
    @shown_date == @current_date
  end

end