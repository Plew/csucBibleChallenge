# frozen_string_literal: true

class WeeklyCheckInComponent < ViewComponent::Base
  # days: array of hashes with keys :date, :day_of_week, :day_of_month, :completed, :group_completion
  def initialize(days:)
    @days = days
  end
end 