class CheckBadgesJob < ApplicationJob
  queue_as :default

  def perform(user_id, challenge_id)
    user = User.find_by(id: user_id)
    challenge = Challenge.find_by(id: challenge_id)
    return unless user && challenge

    newly_awarded = BadgeAwarder.new(user, challenge).call

    if newly_awarded.any?
      cache_key = "badge_notifications/#{user_id}"
      existing = Rails.cache.read(cache_key) || []
      Rails.cache.write(cache_key, existing + newly_awarded, expires_in: 1.hour)
    end
  end
end
