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
end
