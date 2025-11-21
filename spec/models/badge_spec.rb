require 'rails_helper'

RSpec.describe Badge, type: :model do
  describe 'associations' do
    it { should have_many(:user_badges).dependent(:destroy) }
    it { should have_many(:users).through(:user_badges) }
    it { should have_many(:challenges).through(:user_badges) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:icon) }
  end

  describe '#create' do
    it 'is valid with valid attributes' do
      expect(FactoryBot.build(:badge)).to be_valid
    end

    it 'is invalid without a name' do
      badge = FactoryBot.build(:badge, name: nil)
      expect(badge).not_to be_valid
      expect(badge.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a description' do
      badge = FactoryBot.build(:badge, description: nil)
      expect(badge).not_to be_valid
      expect(badge.errors[:description]).to include("can't be blank")
    end

    it 'is invalid without an icon' do
      badge = FactoryBot.build(:badge, icon: nil)
      expect(badge).not_to be_valid
      expect(badge.errors[:icon]).to include("can't be blank")
    end
  end
end
