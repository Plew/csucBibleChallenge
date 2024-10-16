class CheckInComponent < ViewComponent::Base
  def initialize(
    active_date: Current.active_date,
    checked: false
    )
    @checked = checked
    @active_date = active_date
  end

  def previous_date
    (@active_date - 1).strftime('%Y-%m-%d')
  end

  def next_date
    (@active_date + 1).strftime('%Y-%m-%d')
  end

  def hide_next?
    @active_date >= current_date
  end

  def disabled?
    @active_date != current_date
  end

  def display_date
    @active_date.strftime('%A, %b %-d')
  end

  private

  def current_date
    Current.current_date || Date.today
  end
end