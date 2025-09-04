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
