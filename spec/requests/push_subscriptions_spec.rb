require "rails_helper"

RSpec.describe "PushSubscriptions", type: :request do
  let(:user) { create(:user) }

  describe "POST /push_subscriptions" do
    let(:params) do
      {
        endpoint: "https://fcm.googleapis.com/fcm/send/abc123",
        p256dh_key: "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8p8l930ds=",
        auth_key: "tBHItJI5svbpC7-InjCr3A=="
      }
    end

    context "when logged in" do
      before { login_via_session(user) }

      it "creates a push subscription" do
        expect {
          post push_subscriptions_path, params: params, as: :json
        }.to change(PushSubscription, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "associates the subscription with the current user" do
        post push_subscriptions_path, params: params, as: :json

        subscription = PushSubscription.last
        expect(subscription.user).to eq(user)
        expect(subscription.endpoint).to eq(params[:endpoint])
      end

      it "updates an existing subscription with the same endpoint" do
        create(:push_subscription, user: user, endpoint: params[:endpoint])

        expect {
          post push_subscriptions_path, params: params.merge(auth_key: "new_auth_key"), as: :json
        }.not_to change(PushSubscription, :count)

        expect(PushSubscription.find_by(endpoint: params[:endpoint]).auth_key).to eq("new_auth_key")
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post push_subscriptions_path, params: params, as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /push_subscriptions" do
    context "when logged in" do
      before { login_via_session(user) }

      it "destroys the subscription matching the endpoint" do
        subscription = create(:push_subscription, user: user)

        expect {
          delete push_subscriptions_path, params: { endpoint: subscription.endpoint }, as: :json
        }.to change(PushSubscription, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "returns ok even if subscription not found" do
        delete push_subscriptions_path, params: { endpoint: "https://nonexistent.com" }, as: :json
        expect(response).to have_http_status(:ok)
      end

      it "does not destroy another user's subscription" do
        other_user = create(:user)
        subscription = create(:push_subscription, user: other_user)

        expect {
          delete push_subscriptions_path, params: { endpoint: subscription.endpoint }, as: :json
        }.not_to change(PushSubscription, :count)
      end
    end
  end

  describe "POST /push_subscriptions/test" do
    context "when logged in" do
      before { login_via_session(user) }

      it "returns unprocessable entity if user has no subscriptions" do
        post test_push_subscriptions_path, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end

      it "sends a test webpush payload when subscriptions exist" do
        create(:push_subscription, user: user)
        allow(WebPush).to receive(:payload_send).and_return(true)

        post test_push_subscriptions_path, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["sent_count"]).to eq(1)
        expect(WebPush).to have_received(:payload_send)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post test_push_subscriptions_path, as: :json
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
