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

  describe '#active_challenge' do
    let(:user) { create(:user) }
    let(:today) { Date.current }

    context 'with zero enrollments' do
      it 'returns nil' do
        expect(user.active_challenge).to be_nil
      end
    end

    context 'with one in-progress enrollment' do
      let!(:challenge) { create(:challenge, start_date: today - 5.days, end_date: today + 25.days) }

      before { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      it 'returns that challenge' do
        expect(user.active_challenge).to eq(challenge)
      end
    end

    context 'with one ended enrollment (not in progress)' do
      let!(:challenge) { create(:challenge, start_date: today - 60.days, end_date: today - 30.days) }

      before { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      it 'falls back to the most-recently-joined enrollment' do
        expect(user.active_challenge).to eq(challenge)
      end
    end

    context 'with one upcoming enrollment (not yet started)' do
      let!(:challenge) { create(:challenge, start_date: today + 5.days, end_date: today + 35.days) }

      before { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      it 'falls back to the most-recently-joined enrollment' do
        expect(user.active_challenge).to eq(challenge)
      end
    end

    context 'with one in-progress and one ended enrollment' do
      let!(:ended_challenge) { create(:challenge, start_date: today - 60.days, end_date: today - 30.days) }
      let!(:active_ch) { create(:challenge, start_date: today - 5.days, end_date: today + 25.days) }

      before do
        create(:user_challenge_enrollment, user: user, challenge: ended_challenge, created_at: 2.months.ago)
        create(:user_challenge_enrollment, user: user, challenge: active_ch, created_at: 1.week.ago)
      end

      it 'returns the in-progress challenge' do
        expect(user.active_challenge).to eq(active_ch)
      end
    end

    context 'with multiple in-progress enrollments' do
      let!(:older_active) { create(:challenge, start_date: today - 10.days, end_date: today + 20.days) }
      let!(:newer_active) { create(:challenge, start_date: today - 5.days, end_date: today + 25.days) }

      before do
        create(:user_challenge_enrollment, user: user, challenge: older_active, created_at: 2.weeks.ago)
        create(:user_challenge_enrollment, user: user, challenge: newer_active, created_at: 1.week.ago)
      end

      it 'returns the most-recently-joined in-progress challenge' do
        expect(user.active_challenge).to eq(newer_active)
      end
    end

    context 'with multiple ended enrollments and none in progress' do
      let!(:older_ended) { create(:challenge, start_date: today - 120.days, end_date: today - 90.days) }
      let!(:newer_ended) { create(:challenge, start_date: today - 60.days, end_date: today - 30.days) }

      before do
        create(:user_challenge_enrollment, user: user, challenge: older_ended, created_at: 4.months.ago)
        create(:user_challenge_enrollment, user: user, challenge: newer_ended, created_at: 2.months.ago)
      end

      it 'returns the most-recently-joined enrollment overall' do
        expect(user.active_challenge).to eq(newer_ended)
      end
    end
  end

end
