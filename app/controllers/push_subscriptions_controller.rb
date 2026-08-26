class PushSubscriptionsController < ApplicationController
  before_action :require_login

  def create
    endpoint = params[:endpoint] || params.dig(:push_subscription, :endpoint)
    p256dh_key = params[:p256dh_key] || params.dig(:push_subscription, :p256dh_key)
    auth_key = params[:auth_key] || params.dig(:push_subscription, :auth_key)

    subscription = PushSubscription.find_or_initialize_by(endpoint: endpoint)
    subscription.user = current_user
    subscription.p256dh_key = p256dh_key
    subscription.auth_key = auth_key

    if subscription.save
      render json: { success: true, id: subscription.id }, status: :ok
    else
      render json: { success: false, errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = params[:endpoint] || params.dig(:push_subscription, :endpoint)
    subscription = current_user.push_subscriptions.find_by(endpoint: endpoint)
    subscription&.destroy
    head :ok
  end

  def test
    subscriptions = current_user.push_subscriptions
    if subscriptions.empty?
      render json: { success: false, error: "No active push subscriptions found on this account. Please enable the toggle first." }, status: :unprocessable_entity
      return
    end

    vapid = {
      subject: Rails.application.config.webpush.vapid_subject || "mailto:admin@andgodsaid.org",
      public_key: Rails.application.config.webpush.vapid_public_key || ENV["VAPID_PUBLIC_KEY"],
      private_key: Rails.application.config.webpush.vapid_private_key || ENV["VAPID_PRIVATE_KEY"]
    }

    sent_count = 0
    errors = []

    subscriptions.find_each do |subscription|
      begin
        WebPush.payload_send(
          message: {
            title: "And God Said — Notifications Active! 🔔",
            options: {
              body: "Push notifications are working on your device. You'll receive daily reading reminders and group alerts!",
              icon: "/icons/icon-192x192.png",
              badge: "/icons/icon-48x48.png",
              data: { path: "/reading" }
            }
          }.to_json,
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          vapid: vapid
        )
        sent_count += 1
      rescue WebPush::ExpiredSubscription
        subscription.destroy
        errors << "Subscription expired on server"
      rescue WebPush::Error => e
        Rails.logger.warn("Web push test failed for subscription #{subscription.id}: #{e.message}")
        errors << e.message
      rescue => e
        Rails.logger.error("Web push unexpected error: #{e.message}")
        errors << e.message
      end
    end

    if sent_count > 0
      render json: { success: true, sent_count: sent_count }
    else
      render json: { success: false, error: errors.join(", ").presence || "Failed to deliver push notification." }, status: :unprocessable_entity
    end
  end
end
