class CheckInComponent < ViewComponent::Base
  def initialize(
    active_date: Current.browser_date,
    checked: false
    )
    @checked = checked
    @active_date = active_date
  end

  def previous_date
    (@active_date - 1).strftime("%Y-%m-%d")
  end

  def next_date
    (@active_date + 1).strftime("%Y-%m-%d")
  end

  def hide_next?
    @active_date >= browser_date
  end

  def disabled?
    @active_date != browser_date
  end

  def display_date
    @active_date.strftime("%A, %b %-d")
  end

  private

  def browser_date
    Current.browser_date
  end
end
