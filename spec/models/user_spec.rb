require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { FactoryBot.build(:user) } # Use FactoryBot for a default valid user

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('userexample.com').for(:email) }
    it { should_not allow_value('@example.com').for(:email) }

    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe '#create' do
    context 'with valid attributes' do
      it 'is valid' do
        user = FactoryBot.build(:user)
        expect(user).to be_valid
      end
    end

    context 'with invalid attributes' do
      it 'is invalid without a username' do
        user = FactoryBot.build(:user, username: nil)
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can't be blank")
      end

      it 'is invalid without an email' do
        user = FactoryBot.build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with a duplicate username' do
        FactoryBot.create(:user, username: 'testuser')
        user = FactoryBot.build(:user, username: 'testuser')
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('has already been taken')
      end

      it 'is invalid with a duplicate email' do
        FactoryBot.create(:user, email: 'test@example.com')
        user = FactoryBot.build(:user, email: 'TEST@EXAMPLE.COM') # Test case-insensitivity
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end

      it 'is invalid with an incorrect email format' do
        user = FactoryBot.build(:user, email: 'invalid_email')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end

      it 'is invalid without a password' do
        user = FactoryBot.build(:user, password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'is invalid with a short password' do
        user = FactoryBot.build(:user, password: '123')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end
    end
  end
end
