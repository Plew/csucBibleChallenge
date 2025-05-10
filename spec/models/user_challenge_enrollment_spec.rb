require 'rails_helper'

RSpec.describe UserChallengeEnrollment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:challenge) }
  end

  describe 'validations' do
    # Test uniqueness with a persisted record
    # subject is implicitly created by shoulda-matchers for this test
    subject { FactoryBot.create(:user_challenge_enrollment) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:challenge_id).with_message("already enrolled in this challenge") }
  end

  it 'is valid with valid attributes (associated user and challenge)' do
    # FactoryBot.create will ensure associated user and challenge are created and valid
    expect(FactoryBot.create(:user_challenge_enrollment)).to be_valid
  end

  it 'is invalid without a user' do
    enrollment = FactoryBot.build(:user_challenge_enrollment, user: nil)
    expect(enrollment).not_to be_valid
    expect(enrollment.errors[:user]).to include("must exist") # Default error for belongs_to
  end

  it 'is invalid without a challenge' do
    enrollment = FactoryBot.build(:user_challenge_enrollment, challenge: nil)
    expect(enrollment).not_to be_valid
    expect(enrollment.errors[:challenge]).to include("must exist") # Default error for belongs_to
  end
end
