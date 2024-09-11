class DashboardComponent < ViewComponent::Base
  def initialize(shown_date: Date.today.strftime('%Y-%m-%d'), current_date: Date.today.strftime('%Y-%m-%d'))
    @shown_date = shown_date
    @current_date = current_date
  end
end