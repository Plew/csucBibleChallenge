class SendPokeNotificationJob < ApplicationJob
  queue_as :default

  def perform(poke_id)
    poke = Poke.find_by(id: poke_id)
    return unless poke

    poker = poke.poker
    pokee = poke.pokee
    return unless poker && pokee

    subscriptions = pokee.push_subscriptions
    return if subscriptions.empty?

    title = I18n.t("pokes.notification", username: poker.username)
    body = poke.challenge.title

    vapid = {
      subject: Rails.application.config.webpush.vapid_subject || "mailto:admin@andgodsaid.org",
      public_key: Rails.application.config.webpush.vapid_public_key,
      private_key: Rails.application.config.webpush.vapid_private_key
    }

    subscriptions.find_each do |subscription|
      WebPush.payload_send(
        message: { title: title, options: { body: body, icon: "/icons/icon-192x192.png?v=3", badge: "/icons/icon-48x48.png?v=3", data: { path: "/" } } }.to_json,
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
