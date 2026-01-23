# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReadingPresence do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:reading) { create(:reading) }

  before do
    # Clear any existing presence data for this reading
    described_class.leave(user1.id, reading.id)
    described_class.leave(user2.id, reading.id)
  end

  describe ".heartbeat" do
    it "records a user's presence" do
      described_class.heartbeat(user1.id, reading.id)

      expect(described_class.active?(user1.id, reading.id)).to be true
    end

    it "increments the active count" do
      expect {
        described_class.heartbeat(user1.id, reading.id)
      }.to change { described_class.active_count(reading.id) }.by(1)
    end
  end

  describe ".leave" do
    before do
      described_class.heartbeat(user1.id, reading.id)
    end

    it "removes a user's presence" do
      described_class.leave(user1.id, reading.id)

      expect(described_class.active?(user1.id, reading.id)).to be false
    end

    it "decrements the active count" do
      expect {
        described_class.leave(user1.id, reading.id)
      }.to change { described_class.active_count(reading.id) }.by(-1)
    end
  end

  describe ".active_count" do
    it "returns 0 when no users are active" do
      expect(described_class.active_count(reading.id)).to eq(0)
    end

    it "returns the correct count with multiple users" do
      described_class.heartbeat(user1.id, reading.id)
      described_class.heartbeat(user2.id, reading.id)

      expect(described_class.active_count(reading.id)).to eq(2)
    end
  end

  describe ".active_user_ids" do
    it "returns empty array when no users are active" do
      expect(described_class.active_user_ids(reading.id)).to eq([])
    end

    it "returns the IDs of active users" do
      described_class.heartbeat(user1.id, reading.id)
      described_class.heartbeat(user2.id, reading.id)

      expect(described_class.active_user_ids(reading.id)).to contain_exactly(user1.id, user2.id)
    end
  end

  describe ".active?" do
    it "returns false for inactive user" do
      expect(described_class.active?(user1.id, reading.id)).to be false
    end

    it "returns true for active user" do
      described_class.heartbeat(user1.id, reading.id)

      expect(described_class.active?(user1.id, reading.id)).to be true
    end
  end
end
