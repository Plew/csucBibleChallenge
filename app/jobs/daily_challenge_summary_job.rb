class DailyChallengeSummaryJob < ApplicationJob
  queue_as :default

  def perform
    Challenge.active.includes(:creator, :users).find_each do |challenge|
      ChallengeMailer.daily_summary(challenge).deliver_now
    end
  end
end
