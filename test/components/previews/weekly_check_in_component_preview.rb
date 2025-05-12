# frozen_string_literal: true

class WeeklyCheckInComponentPreview < ViewComponent::Preview
  def default
    today = Date.today
    days = 6.downto(0).map do |i|
      date = today - (6 - i)
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        completed: [0, 2, 4, 6].include?(i), # Example: some days completed
        group_completion: [0, 25, 50, 75, 100, 33, 66][i]
      }
    end
    render(WeeklyCheckInComponent.new(days: days))
  end
end 