class DashboardComponent < ViewComponent::Base
  def initialize(checked: false, day_offset: 0)
    @checked = checked
    @day_offset = day_offset
  end
end