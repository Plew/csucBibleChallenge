require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:user_group_enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:user_group_enrollments) }
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
