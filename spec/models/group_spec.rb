require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should have_many(:user_challenge_enrollments).dependent(:nullify) }
  end

  describe 'validations' do
    subject { FactoryBot.create(:group) } # Create for uniqueness check

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:challenge_id).with_message("name should be unique within the challenge") }
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:group)).to be_valid
  end
end
