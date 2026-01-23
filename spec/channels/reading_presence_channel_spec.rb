# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReadingPresenceChannel, type: :channel do
  let(:user) { create(:user) }
  let(:reading) { create(:reading) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "subscribes to the reading's presence stream" do
      subscribe(reading_id: reading.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("reading_#{reading.id}_presence")
    end

    it "records the user's presence" do
      subscribe(reading_id: reading.id)

      expect(ReadingPresence.active?(user.id, reading.id)).to be true
    end

    it "rejects subscription without reading_id" do
      subscribe(reading_id: nil)

      expect(subscription).to be_rejected
    end
  end

  describe "#unsubscribed" do
    before do
      subscribe(reading_id: reading.id)
    end

    it "removes the user's presence" do
      subscription.unsubscribe_from_channel

      expect(ReadingPresence.active?(user.id, reading.id)).to be false
    end
  end

  describe "#heartbeat" do
    before do
      subscribe(reading_id: reading.id)
    end

    it "updates the user's presence" do
      expect(ReadingPresence).to receive(:heartbeat).with(user.id, reading.id)

      perform :heartbeat
    end
  end

  describe "#inactive" do
    before do
      subscribe(reading_id: reading.id)
    end

    it "removes the user's presence" do
      expect(ReadingPresence).to receive(:leave).with(user.id, reading.id)

      perform :inactive
    end
  end
end
