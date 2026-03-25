require 'rails_helper'

RSpec.describe EmailLoginToken, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:challenge) }
    it { should belong_to(:reading) }
  end

  describe 'validations' do
    it 'validates presence of token' do
      token = build(:email_login_token)
      token.token = nil
      # The before_validation callback will generate a token
      expect(token).to be_valid
      expect(token.token).to be_present
    end

    it 'validates uniqueness of token' do
      existing_token = create(:email_login_token)
      duplicate = build(:email_login_token, token: existing_token.token)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'callbacks' do
    describe 'generate_token' do
      it 'generates a token before creation' do
        token = build(:email_login_token, token: nil)
        token.save
        expect(token.token).to be_present
      end

      it 'does not overwrite an existing token' do
        existing_token = 'existing_token_123'
        token = build(:email_login_token, token: existing_token)
        token.save
        expect(token.token).to eq(existing_token)
      end

      it 'generates a unique token' do
        token1 = create(:email_login_token)
        token2 = create(:email_login_token)
        expect(token1.token).not_to eq(token2.token)
      end
    end
  end

  describe 'scopes' do
    describe '.unused' do
      let!(:used_token) { create(:email_login_token, clicked_at: 1.hour.ago) }
      let!(:unused_token) { create(:email_login_token, clicked_at: nil) }

      it 'returns only unused tokens' do
        expect(EmailLoginToken.unused).to include(unused_token)
        expect(EmailLoginToken.unused).not_to include(used_token)
      end
    end

    describe '.recent' do
      let!(:old_token) { create(:email_login_token, created_at: 8.days.ago) }
      let!(:recent_token) { create(:email_login_token, created_at: 1.hour.ago) }

      it 'returns only tokens created within last 7 days' do
        expect(EmailLoginToken.recent).to include(recent_token)
        expect(EmailLoginToken.recent).not_to include(old_token)
      end
    end
  end

  describe '#mark_as_clicked!' do
    let(:token) { create(:email_login_token) }

    it 'sets clicked_at to current time on first use' do
      expect(token.clicked_at).to be_nil
      token.mark_as_clicked!
      expect(token.clicked_at).to be_within(1.second).of(Time.current)
    end

    it 'does not overwrite clicked_at on subsequent uses' do
      token.mark_as_clicked!
      original_clicked_at = token.clicked_at
      travel_to 1.hour.from_now do
        token.mark_as_clicked!
        expect(token.reload.clicked_at).to be_within(1.second).of(original_clicked_at)
      end
    end
  end

  describe '#clicked?' do
    it 'returns true when clicked_at is present' do
      token = create(:email_login_token, clicked_at: 1.hour.ago)
      expect(token.clicked?).to be true
    end

    it 'returns false when clicked_at is nil' do
      token = create(:email_login_token, clicked_at: nil)
      expect(token.clicked?).to be false
    end
  end

  describe '#valid_for_login?' do
    context 'when token was created within last 7 days' do
      let(:token) { create(:email_login_token, created_at: 1.hour.ago) }

      it 'returns true' do
        expect(token.valid_for_login?).to be true
      end
    end

    context 'when token was created 6 days ago' do
      let(:token) { create(:email_login_token, created_at: 6.days.ago) }

      it 'returns true' do
        expect(token.valid_for_login?).to be true
      end
    end

    context 'when token has been clicked but is within 7 days' do
      let(:token) { create(:email_login_token, created_at: 1.hour.ago, clicked_at: 30.minutes.ago) }

      it 'returns true (reusable)' do
        expect(token.valid_for_login?).to be true
      end
    end

    context 'when token is older than 7 days' do
      let(:token) { create(:email_login_token, created_at: 8.days.ago) }

      it 'returns false' do
        expect(token.valid_for_login?).to be false
      end
    end

    context 'when token is older than 7 days even if never clicked' do
      let(:token) { create(:email_login_token, created_at: 8.days.ago, clicked_at: nil) }

      it 'returns false' do
        expect(token.valid_for_login?).to be false
      end
    end
  end
end
