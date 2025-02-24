class LastSevenDaysComponent < ViewComponent::Base
  def initialize(active_date:)
    @active_date = active_date
  end

  def dates
    6.downto(0).map do |n|
      date = n.days.ago.to_date
      {
        day_name: date.strftime("%a"),
        day_number: date.day,
        date: date,
        active: date == @active_date.to_date
      }
    end
  end
end 