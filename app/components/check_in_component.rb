class CheckInComponent < ViewComponent::Base
  def initialize(
    shown_date:,
    checked: false
    )
    @checked = checked
    @shown_date = shown_date
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

  def disabled?
    @shown_date != Current.date_string
  end

  def display_date
    parsed_date.strftime('%A, %b %-d')
  end
end