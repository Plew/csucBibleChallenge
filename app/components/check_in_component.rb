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
    @shown_date.blank? ? Current.date : Date.parse(@shown_date)
  end

  def next_date
    (parsed_date + 1).strftime('%Y-%m-%d')
  end

  def hide_next?
    parsed_date >= Current.date
  end

  def disabled?
    Current.date != parsed_date
  end

  def display_date
    parsed_date.strftime('%A, %b %-d')
  end
end