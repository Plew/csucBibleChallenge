require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:user_challenge_enrollments).dependent(:destroy) }
    it { should have_many(:challenges).through(:user_challenge_enrollments) }
    it { should have_many(:user_readings).dependent(:destroy) }
    it { should have_many(:completed_readings).through(:user_readings).source(:reading) }
  end

  describe 'active_storage_attachments' do
    let(:user) { FactoryBot.create(:user) }
    let(:file_path) { Rails.root.join('spec', 'fixtures', 'files', 'test_avatar.png') }
    let(:file) { Rack::Test::UploadedFile.new(file_path, 'image/png') }

    before do
      # Create a dummy file for testing if it doesn't exist
      FileUtils.mkdir_p(File.dirname(file_path))
      FileUtils.touch(file_path) unless File.exist?(file_path)
    end

    it { should have_one_attached(:avatar) }

    it 'can have an avatar attached' do
      user.avatar.attach(file)
      expect(user.avatar).to be_attached
    end

    it 'processes a thumb variant' do
      user.avatar.attach(file)
      expect(user.avatar.variant(:thumb)).to be_a(ActiveStorage::VariantWithRecord)
    end

    it 'processes a medium variant' do
      user.avatar.attach(file)
      expect(user.avatar.variant(:medium)).to be_a(ActiveStorage::VariantWithRecord)
    end
  end

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

  describe 'scopes' do
    describe '.wants_daily_email' do
      let!(:user_with_email) { create(:user, daily_email: true) }
      let!(:user_without_email) { create(:user, daily_email: false) }

      it 'returns users who want daily emails' do
        expect(User.wants_daily_email).to include(user_with_email)
        expect(User.wants_daily_email).not_to include(user_without_email)
      end

      it 'works correctly when users have mixed preferences' do
        result = User.wants_daily_email
        expect(result.count).to eq(1)
        expect(result.first).to eq(user_with_email)
      end
    end
  end

  describe '#can_create_challenges?' do
    it 'returns true for admin users' do
      user = create(:user, admin: true, can_create_challenges: false)
      expect(user.can_create_challenges?).to be true
    end

    it 'returns true for users with can_create_challenges flag' do
      user = create(:user, admin: false, can_create_challenges: true)
      expect(user.can_create_challenges?).to be true
    end

    it 'returns false for regular users without the flag' do
      user = create(:user, admin: false, can_create_challenges: false)
      expect(user.can_create_challenges?).to be false
    end
  end

  describe '#owns_challenge?' do
    let(:user) { create(:user) }
    let(:challenge) { create(:challenge, creator: user) }
    let(:other_challenge) { create(:challenge) }

    it 'returns true for a challenge the user created' do
      expect(user.owns_challenge?(challenge)).to be true
    end

    it 'returns false for a challenge the user did not create' do
      expect(user.owns_challenge?(other_challenge)).to be false
    end

    it 'returns false for nil' do
      expect(user.owns_challenge?(nil)).to be false
    end
  end

  describe 'daily_email attribute' do
    it 'defaults to true for new users' do
      user = User.new
      expect(user.daily_email).to be_truthy
    end

    it 'can be set to false' do
      user = create(:user, daily_email: false)
      expect(user.daily_email).to be_falsey
    end

    it 'can be set to true' do
      user = create(:user, daily_email: true)
      expect(user.daily_email).to be_truthy
    end
  end

  describe '#create_unsubscribe_digest' do
    let(:user) { create(:user) }

    it 'generates a unique token' do
      token = user.create_unsubscribe_digest
      expect(token).to be_present
      expect(token.length).to be > 20
    end

    it 'saves the token to unsubscribe_digest' do
      token = user.create_unsubscribe_digest
      user.reload
      expect(user.unsubscribe_digest).to eq(token)
    end

    it 'sets unsubscribe_sent_at to current time' do
      user.create_unsubscribe_digest
      user.reload
      expect(user.unsubscribe_sent_at).to be_within(1.second).of(Time.current)
    end

    it 'generates different tokens on each call' do
      token1 = user.create_unsubscribe_digest
      token2 = user.create_unsubscribe_digest
      expect(token1).not_to eq(token2)
    end
  end

  describe '#unsubscribe_token_valid?' do
    let(:user) { create(:user) }

    context 'when token was just created' do
      it 'returns true' do
        user.create_unsubscribe_digest
        expect(user.unsubscribe_token_valid?).to be true
      end
    end

    context 'when token is within 24 hours' do
      it 'returns true' do
        user.create_unsubscribe_digest
        user.update_column(:unsubscribe_sent_at, 23.hours.ago)
        expect(user.unsubscribe_token_valid?).to be true
      end
    end

    context 'when token is older than 24 hours' do
      it 'returns false' do
        user.create_unsubscribe_digest
        user.update_column(:unsubscribe_sent_at, 25.hours.ago)
        expect(user.unsubscribe_token_valid?).to be false
      end
    end

    context 'when unsubscribe_sent_at is nil' do
      it 'returns false' do
        user.unsubscribe_digest = 'some_token'
        user.unsubscribe_sent_at = nil
        user.save!(validate: false)
        expect(user.unsubscribe_token_valid?).to eq(false)
      end
    end
  end
end
