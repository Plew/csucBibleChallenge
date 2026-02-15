require 'rails_helper'

RSpec.describe Challenge, type: :model do
  describe 'associations' do
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:user_challenge_enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:user_challenge_enrollments) }
    it { should have_many(:readings).dependent(:destroy) }
    it { should have_many(:groups).dependent(:destroy) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:challenge) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:timezone) }
    it { should validate_inclusion_of(:timezone).in_array(ActiveSupport::TimeZone.all.map(&:name)).with_message(/is not a valid timezone/) }
    it { should validate_uniqueness_of(:invitation_token).allow_nil }

    context 'when end_date is before start_date' do
      it 'is invalid' do
        challenge = FactoryBot.build(:challenge, start_date: Date.today, end_date: Date.today - 1.day)
        expect(challenge).not_to be_valid
        expect(challenge.errors[:end_date]).to include("must be on or after the start date")
      end
    end

    context 'when end_date is the same as start_date' do
      it 'is valid' do
        challenge = FactoryBot.build(:challenge, start_date: Date.today, end_date: Date.today)
        expect(challenge).to be_valid
      end
    end

    context 'when end_date is after start_date' do
      it 'is valid' do
        challenge = FactoryBot.build(:challenge, start_date: Date.today, end_date: Date.today + 1.day)
        expect(challenge).to be_valid
      end
    end
  end

  describe '#create' do
    it 'is valid with valid attributes' do
      expect(FactoryBot.build(:challenge)).to be_valid
    end
  end

  describe 'invitation token' do
    describe 'callbacks' do
      it 'generates an invitation token before creation' do
        challenge = FactoryBot.build(:challenge, invitation_token: nil)
        expect(challenge.invitation_token).to be_nil
        challenge.save!
        expect(challenge.invitation_token).to be_present
        expect(challenge.invitation_token.length).to eq(6)
      end

      it 'generates unique invitation tokens' do
        challenge1 = FactoryBot.create(:challenge)
        challenge2 = FactoryBot.create(:challenge)
        expect(challenge1.invitation_token).not_to eq(challenge2.invitation_token)
      end
    end

    describe '#generate_invitation_token' do
      let(:challenge) { FactoryBot.build(:challenge) }

      it 'generates a 6-character alphanumeric token' do
        challenge.generate_invitation_token
        expect(challenge.invitation_token).to match(/\A[a-zA-Z0-9]{6}\z/)
      end

      it 'ensures token uniqueness' do
        existing_challenge = FactoryBot.create(:challenge)
        allow(SecureRandom).to receive(:alphanumeric).and_return(existing_challenge.invitation_token, 'ABC123')

        challenge.generate_invitation_token
        expect(challenge.invitation_token).to eq('ABC123')
      end
    end

    describe '#regenerate_invitation_token!' do
      let(:challenge) { FactoryBot.create(:challenge) }

      it 'generates a new token and saves the challenge' do
        original_token = challenge.invitation_token
        challenge.regenerate_invitation_token!
        expect(challenge.invitation_token).not_to eq(original_token)
        expect(challenge.reload.invitation_token).not_to eq(original_token)
      end
    end
  end

  describe '#owned_by?' do
    let(:creator) { create(:user) }
    let(:challenge) { create(:challenge, creator: creator) }
    let(:other_user) { create(:user) }

    it 'returns true for the creator' do
      expect(challenge.owned_by?(creator)).to be true
    end

    it 'returns false for another user' do
      expect(challenge.owned_by?(other_user)).to be false
    end

    it 'returns false for nil' do
      expect(challenge.owned_by?(nil)).to be false
    end
  end

  describe 'deletion' do
    let(:creator) { FactoryBot.create(:user, admin: true) }
    let(:challenge) { FactoryBot.create(:challenge, creator: creator) }
    let(:other_user) { FactoryBot.create(:user) }

    before do
      # Create related records
      @enrollment = FactoryBot.create(:user_challenge_enrollment, challenge: challenge, user: other_user)
      @reading = FactoryBot.create(:reading, challenge: challenge)
      @group = FactoryBot.create(:group, challenge: challenge)
      @user_reading = FactoryBot.create(:user_reading, user: other_user, reading: @reading)
    end

    it 'destroys all associated records when deleted' do
      challenge_id = challenge.id

      expect { challenge.destroy }
        .to change(Challenge, :count).by(-1)
        .and change(UserChallengeEnrollment, :count).by(-1)
        .and change(Reading, :count).by(-1)
        .and change(Group, :count).by(-1)
        .and change(UserReading, :count).by(-1)
    end

    it 'does not destroy users when challenge is deleted' do
      expect { challenge.destroy }.not_to change(User, :count)
    end
  end
end
