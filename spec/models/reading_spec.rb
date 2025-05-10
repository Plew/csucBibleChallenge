require 'rails_helper'

RSpec.describe Reading, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:reading) } # Use FactoryBot

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:scheduled_date) }
    # Presence of challenge is implicitly tested by `belong_to` matcher
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:reading)).to be_valid # build should be fine if challenge is created by factory
  end

  it 'is invalid without a title' do
    reading = FactoryBot.build(:reading, title: nil)
    expect(reading).not_to be_valid
    expect(reading.errors[:title]).to include("can't be blank")
  end

  it 'is invalid without a scheduled_date' do
    reading = FactoryBot.build(:reading, scheduled_date: nil)
    expect(reading).not_to be_valid
    expect(reading.errors[:scheduled_date]).to include("can't be blank")
  end

  it 'is invalid without a challenge' do
    reading = FactoryBot.build(:reading, challenge: nil)
    expect(reading).not_to be_valid
    expect(reading.errors[:challenge]).to include("must exist")
  end
end
