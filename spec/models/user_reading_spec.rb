require 'rails_helper'

RSpec.describe UserReading, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:reading) }
  end

  describe 'validations' do
    subject { FactoryBot.create(:user_reading) } # Create for uniqueness test

    it { should validate_uniqueness_of(:user_id).scoped_to(:reading_id).with_message("has already marked this reading") }
    it { should validate_presence_of(:completed_on) }
    # Presence of user and reading is implicitly tested by `belong_to` matcher
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:user_reading)).to be_valid
  end
end
