require "rails_helper"

RSpec.describe SendPokeNotificationJob, type: :job do
  let(:challenge) { create(:challenge) }
  let(:poker) { create(:user, username: "Phil") }
  let(:pokee) { create(:user) }
  let(:poke) { create(:poke, poker: poker, pokee: pokee, challenge: challenge) }

  before do
    allow(Rails.application.config.webpush).to receive(:vapid_public_key).and_return("test_public_key")
    allow(Rails.application.config.webpush).to receive(:vapid_private_key).and_return("test_private_key")
  end

  it "sends a push notification to the pokee" do
    subscription = create(:push_subscription, user: pokee)

    expect(WebPush).to receive(:payload_send).with(
      hash_including(
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key
      )
    )

    SendPokeNotificationJob.perform_now(poke.id)
  end

  it "includes the poker's username in the notification" do
    create(:push_subscription, user: pokee)

    expect(WebPush).to receive(:payload_send) do |args|
      payload = JSON.parse(args[:message])
      expect(payload["title"]).to include("Phil")
      expect(payload["title"]).to include("reminding")
    end

    SendPokeNotificationJob.perform_now(poke.id)
  end

  it "does nothing if the pokee has no push subscriptions" do
    expect(WebPush).not_to receive(:payload_send)

    SendPokeNotificationJob.perform_now(poke.id)
  end

  it "handles missing poke gracefully" do
    expect { SendPokeNotificationJob.perform_now(-1) }.not_to raise_error
  end

  it "destroys expired subscriptions" do
    subscription = create(:push_subscription, user: pokee)

    response = instance_double(Net::HTTPResponse, body: "expired", code: "410")
    allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.new(response, "localhost"))

    SendPokeNotificationJob.perform_now(poke.id)

    expect(PushSubscription.find_by(id: subscription.id)).to be_nil
  end

  it "logs a warning on other WebPush errors without raising" do
    create(:push_subscription, user: pokee)

    allow(WebPush).to receive(:payload_send).and_raise(WebPush::Error.new("test error"))

    expect(Rails.logger).to receive(:warn).with(/Web push failed/)

    expect { SendPokeNotificationJob.perform_now(poke.id) }.not_to raise_error
  end
end
