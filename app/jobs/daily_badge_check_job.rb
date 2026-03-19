class DailyBadgeCheckJob < ApplicationJob
  queue_as :default

  def perform
    Challenge.active.find_each do |challenge|
      challenge.users.find_each do |user|
        CheckBadgesJob.perform_later(user.id, challenge.id)
      end
    end
  end
end
