class CalculateSprintWinnersJob < ApplicationJob
  queue_as :default

  def perform
    Challenge.find_each do |challenge|
      tz = challenge.timezone.present? ? ActiveSupport::TimeZone[challenge.timezone] : Time.zone
      yesterday_in_tz = tz.now.to_date - 1.day

      challenge.sprints.where(end_date: yesterday_in_tz).find_each do |sprint|
        next if sprint.winners_calculated?

        sprint.calculate_winners!
      end
    end
  end
end
