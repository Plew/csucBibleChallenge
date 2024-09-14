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
    (parsed_date - 1).strftime('%Y-%m-%d')
  end

  def parsed_date
    @shown_date.blank? ? Date.today : Date.parse(@shown_date)
  end

  def next_date
    (parsed_date + 1).strftime('%Y-%m-%d')
  end

  def hide_next?
    @shown_date == Current.date_string
  end

end