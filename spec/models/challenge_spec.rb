require 'rails_helper'

RSpec.describe Challenge, type: :model do
  describe 'validations' do
    subject { FactoryBot.build(:challenge) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }

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
end
