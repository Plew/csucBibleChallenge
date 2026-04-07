class SendReadingNotificationJob < ApplicationJob
  include ApplicationHelper

  queue_as :default

  def perform(user_id, reading_id)
    user = User.find_by(id: user_id)
    reading = Reading.find_by(id: reading_id)
    return unless user && reading

    challenge = reading.challenge
    return unless challenge

    # Find the user's group for this challenge
    group = user.groups.find_by(challenge_id: challenge.id)
    return unless group

    book_name = book_number_to_name(reading.book_number)
    reading_title = "#{book_name} #{reading.chapter_number}"
    title = "#{user.username} read #{reading_title}"
    body = "in #{group.name}"

    # Get all other group members with push subscriptions
    group_member_ids = group.users.where.not(id: user.id).pluck(:id)
    return if group_member_ids.empty?

    subscriptions = PushSubscription.where(user_id: group_member_ids)
    return if subscriptions.empty?

    vapid = {
      public_key: Rails.application.config.webpush.vapid_public_key,
      private_key: Rails.application.config.webpush.vapid_private_key
    }

    subscriptions.find_each do |subscription|
      WebPush.payload_send(
        message: { title: title, options: { body: body, icon: "/icons/icon-192x192.png", data: { path: "/" } } }.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: vapid
      )
    rescue WebPush::ExpiredSubscription
      subscription.destroy
    rescue WebPush::Error => e
      Rails.logger.warn("Web push failed for subscription #{subscription.id}: #{e.message}")
    end
  end
end
