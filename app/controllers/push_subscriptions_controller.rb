class PushSubscriptionsController < ApplicationController
  before_action :require_login

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.p256dh_key = params[:p256dh_key]
    subscription.auth_key = params[:auth_key]

    if subscription.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    subscription = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy
    head :ok
  end

  def test
    subscriptions = current_user.push_subscriptions
    if subscriptions.empty?
      render json: { success: false, error: "No active push subscriptions found on this account." }, status: :unprocessable_entity
      return
    end

    vapid = {
      public_key: Rails.application.config.webpush.vapid_public_key,
      private_key: Rails.application.config.webpush.vapid_private_key
    }

    sent_count = 0
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
      rescue WebPush::Error => e
        Rails.logger.warn("Web push test failed for subscription #{subscription.id}: #{e.message}")
      end
    end

    render json: { success: true, sent_count: sent_count }
  end
end
