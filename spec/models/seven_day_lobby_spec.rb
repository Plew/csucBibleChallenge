# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SevenDayLobby, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { create(:seven_day_lobby) }

    it { should validate_presence_of(:challenge_id) }
    it { should validate_presence_of(:user_id) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:challenge_id) }
  end

  describe '.participants_for_challenge' do
    let(:challenge) { create(:challenge) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:other_challenge) { create(:challenge) }

    before do
      create(:seven_day_lobby, challenge: challenge, user: user1)
      create(:seven_day_lobby, challenge: challenge, user: user2)
      create(:seven_day_lobby, challenge: other_challenge, user: user3)
    end

    it 'returns all users in the lobby for a specific challenge' do
      participants = SevenDayLobby.participants_for_challenge(challenge)

      expect(participants).to contain_exactly(user1, user2)
      expect(participants).not_to include(user3)
    end

    it 'returns empty array when no participants in lobby' do
      empty_challenge = create(:challenge)
      participants = SevenDayLobby.participants_for_challenge(empty_challenge)

      expect(participants).to be_empty
    end
  end

  describe '.user_in_lobby?' do
    let(:challenge) { create(:challenge) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before do
      create(:seven_day_lobby, challenge: challenge, user: user)
    end

    it 'returns true when user is in the lobby' do
      expect(SevenDayLobby.user_in_lobby?(user, challenge)).to be true
    end

    it 'returns false when user is not in the lobby' do
      expect(SevenDayLobby.user_in_lobby?(other_user, challenge)).to be false
    end
  end
end
