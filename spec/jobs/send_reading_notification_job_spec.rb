require "rails_helper"

RSpec.describe SendReadingNotificationJob, type: :job do
  let(:challenge) { create(:challenge) }
  let(:group) { create(:group, challenge: challenge) }
  let(:reader) { create(:user) }
  let(:group_mate) { create(:user) }
  let(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 3) }

  before do
    create(:user_group_enrollment, user: reader, group: group)
    create(:user_group_enrollment, user: group_mate, group: group)

    allow(Rails.application.config.webpush).to receive(:vapid_public_key).and_return("test_public_key")
    allow(Rails.application.config.webpush).to receive(:vapid_private_key).and_return("test_private_key")
  end

  it "sends a push notification to group mates with subscriptions" do
    subscription = create(:push_subscription, user: group_mate)

    expect(WebPush).to receive(:payload_send).with(
      hash_including(
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key
      )
    )

    SendReadingNotificationJob.perform_now(reader.id, reading.id)
  end

  it "does not send a notification to the reader themselves" do
    create(:push_subscription, user: reader)

    expect(WebPush).not_to receive(:payload_send)

    SendReadingNotificationJob.perform_now(reader.id, reading.id)
  end

  it "does nothing if the user has no group for the challenge" do
    user_without_group = create(:user)

    expect(WebPush).not_to receive(:payload_send)

    SendReadingNotificationJob.perform_now(user_without_group.id, reading.id)
  end

  it "does nothing if no group mates have subscriptions" do
    expect(WebPush).not_to receive(:payload_send)

    SendReadingNotificationJob.perform_now(reader.id, reading.id)
  end

  it "sends to multiple group mates" do
    another_mate = create(:user)
    create(:user_group_enrollment, user: another_mate, group: group)
    create(:push_subscription, user: group_mate)
    create(:push_subscription, user: another_mate)

    expect(WebPush).to receive(:payload_send).twice

    SendReadingNotificationJob.perform_now(reader.id, reading.id)
  end

  it "includes the book name and chapter in the notification" do
    create(:push_subscription, user: group_mate)

    expect(WebPush).to receive(:payload_send) do |args|
      payload = JSON.parse(args[:message])
      expect(payload["title"]).to include(reader.username)
      expect(payload["title"]).to include("3")
    end

    SendReadingNotificationJob.perform_now(reader.id, reading.id)
  end

  it "destroys expired subscriptions" do
    subscription = create(:push_subscription, user: group_mate)

    response = instance_double(Net::HTTPResponse, body: "expired", code: "410")
    allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.new(response, "localhost"))

    SendReadingNotificationJob.perform_now(reader.id, reading.id)

    expect(PushSubscription.find_by(id: subscription.id)).to be_nil
  end

  it "logs a warning on other WebPush errors without raising" do
    create(:push_subscription, user: group_mate)

    allow(WebPush).to receive(:payload_send).and_raise(WebPush::Error.new("test error"))

    expect(Rails.logger).to receive(:warn).with(/Web push failed/)

    expect { SendReadingNotificationJob.perform_now(reader.id, reading.id) }.not_to raise_error
  end

  it "does not send notifications for past readings" do
    past_reading = create(:reading, challenge: challenge, book_number: 1, chapter_number: 5, scheduled_date: 3.days.ago.to_date)
    create(:push_subscription, user: group_mate)

    expect(WebPush).not_to receive(:payload_send)

    SendReadingNotificationJob.perform_now(reader.id, past_reading.id)
  end

  it "does not send notifications for future readings" do
    future_reading = create(:reading, challenge: challenge, book_number: 1, chapter_number: 6, scheduled_date: 3.days.from_now.to_date)
    create(:push_subscription, user: group_mate)

    expect(WebPush).not_to receive(:payload_send)

    SendReadingNotificationJob.perform_now(reader.id, future_reading.id)
  end

  it "handles missing user gracefully" do
    expect { SendReadingNotificationJob.perform_now(-1, reading.id) }.not_to raise_error
  end

  it "handles missing reading gracefully" do
    expect { SendReadingNotificationJob.perform_now(reader.id, -1) }.not_to raise_error
  end
end
