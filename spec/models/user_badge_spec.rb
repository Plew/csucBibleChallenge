# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBadge, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:challenge) }
  end

  describe "validations" do
    subject { build(:user_badge) }

    it { should validate_presence_of(:badge_key) }

    it "validates badge_key is in BadgeCatalog" do
      badge = build(:user_badge, badge_key: "nonexistent_badge")
      expect(badge).not_to be_valid
      expect(badge.errors[:badge_key]).to be_present
    end

    it "validates uniqueness scoped to user and challenge" do
      user = create(:user)
      challenge = create(:challenge)
      create(:user_badge, user: user, challenge: challenge, badge_key: "chapters_50")

      duplicate = build(:user_badge, user: user, challenge: challenge, badge_key: "chapters_50")
      expect(duplicate).not_to be_valid
    end

    it "allows same badge_key for different users" do
      challenge = create(:challenge)
      create(:user_badge, challenge: challenge, badge_key: "chapters_50")

      other = build(:user_badge, challenge: challenge, badge_key: "chapters_50")
      expect(other).to be_valid
    end

    it "allows same badge_key for different challenges" do
      user = create(:user)
      create(:user_badge, user: user, badge_key: "chapters_50")

      other = build(:user_badge, user: user, badge_key: "chapters_50")
      expect(other).to be_valid
    end
  end

  describe "#badge" do
    it "returns the BadgeCatalog definition" do
      badge = build(:user_badge, badge_key: "streak_7")
      expect(badge.badge).to eq(BadgeCatalog.find("streak_7"))
      expect(badge.badge.category).to eq("streak")
    end
  end
end
