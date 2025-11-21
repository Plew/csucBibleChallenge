require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:badge) }
    it { should belong_to(:challenge) }
  end

  describe 'validations' do
    let(:user) { FactoryBot.create(:user) }
    let(:badge) { FactoryBot.create(:badge) }
    let(:challenge) { FactoryBot.create(:challenge) }

    it 'is valid with valid attributes' do
      user_badge = FactoryBot.build(:user_badge, user: user, badge: badge, challenge: challenge)
      expect(user_badge).to be_valid
    end

    it 'prevents duplicate badges for the same user and challenge' do
      FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge)
      duplicate = FactoryBot.build(:user_badge, user: user, badge: badge, challenge: challenge)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("already has this badge for this challenge")
    end

    it 'allows the same user to have the same badge in different challenges' do
      challenge2 = FactoryBot.create(:challenge, name: "Challenge 2")

      FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge)
      user_badge2 = FactoryBot.build(:user_badge, user: user, badge: badge, challenge: challenge2)

      expect(user_badge2).to be_valid
    end

    it 'allows different users to have the same badge in the same challenge' do
      user2 = FactoryBot.create(:user, username: "user2", email: "user2@example.com")

      FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge)
      user_badge2 = FactoryBot.build(:user_badge, user: user2, badge: badge, challenge: challenge)

      expect(user_badge2).to be_valid
    end

    it 'allows the same user to have different badges in the same challenge' do
      badge2 = FactoryBot.create(:badge, name: "Badge 2")

      FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge)
      user_badge2 = FactoryBot.build(:user_badge, user: user, badge: badge2, challenge: challenge)

      expect(user_badge2).to be_valid
    end
  end

  describe 'challenge scoping' do
    let(:user) { FactoryBot.create(:user) }
    let(:badge) { FactoryBot.create(:badge) }
    let(:challenge1) { FactoryBot.create(:challenge, name: "Challenge 1") }
    let(:challenge2) { FactoryBot.create(:challenge, name: "Challenge 2") }

    it 'badges are scoped to specific challenges' do
      # User earns badge in challenge 1
      user_badge1 = FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge1)

      # User's badges should only include those from challenge 1
      expect(user.user_badges.where(challenge: challenge1).count).to eq(1)
      expect(user.user_badges.where(challenge: challenge2).count).to eq(0)
    end

    it 'user starts with no badges in a new challenge' do
      # User earns badge in challenge 1
      FactoryBot.create(:user_badge, user: user, badge: badge, challenge: challenge1)

      # When user joins challenge 2, they should have no badges there
      expect(user.user_badges.where(challenge: challenge2).count).to eq(0)
    end
  end
end
