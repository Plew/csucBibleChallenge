require 'rails_helper'

RSpec.describe Challenge, type: :model do
  describe 'associations' do
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:user_challenge_enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:user_challenge_enrollments) }
    it { should have_many(:readings).dependent(:destroy) }
    it { should have_many(:groups).dependent(:destroy) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:challenge) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:timezone) }
    it { should validate_inclusion_of(:timezone).in_array(ActiveSupport::TimeZone.all.map(&:name)).with_message(/is not a valid timezone/) }
    it { should validate_uniqueness_of(:invitation_token).allow_nil }

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

    describe 'schedule options validations' do
      it 'validates chapters_per_day is greater than or equal to 1' do
        challenge = FactoryBot.build(:challenge, chapters_per_day: 0)
        expect(challenge).not_to be_valid
        expect(challenge.errors[:chapters_per_day]).to be_present

        challenge.chapters_per_day = 3
        expect(challenge).to be_valid
      end

      it 'normalizes skip_days_of_week_list to integers and computes reading_days_of_week_list' do
        challenge = FactoryBot.build(:challenge, skip_days_of_week: ["0", "6"])
        expect(challenge.skip_days_of_week_list).to eq([0, 6])
        expect(challenge.reading_days_of_week_list).to eq([1, 2, 3, 4, 5])
      end

      it 'normalizes skip_dates_list to Date objects' do
        challenge = FactoryBot.build(:challenge, skip_dates: ["2026-12-25", "2027-01-01"])
        expect(challenge.skip_dates_list).to eq([Date.new(2026, 12, 25), Date.new(2027, 1, 1)])
      end

      it 'accurately identifies reading days with reading_day?' do
        challenge = FactoryBot.build(
          :challenge,
          start_date: Date.new(2026, 10, 1),
          end_date: Date.new(2026, 10, 31),
          skip_days_of_week: [0, 6], # Skip weekends
          skip_dates: ["2026-10-15"]
        )

        # 2026-10-01 is a Thursday (reading day)
        expect(challenge.reading_day?(Date.new(2026, 10, 1))).to be true
        # 2026-10-03 is a Saturday (skipped by wday)
        expect(challenge.reading_day?(Date.new(2026, 10, 3))).to be false
        # 2026-10-04 is a Sunday (skipped by wday)
        expect(challenge.reading_day?(Date.new(2026, 10, 4))).to be false
        # 2026-10-15 is a Thursday (skipped by specific date)
        expect(challenge.reading_day?(Date.new(2026, 10, 15))).to be false
        # Outside range
        expect(challenge.reading_day?(Date.new(2026, 9, 30))).to be false
      end
    end
  end

  describe '#create' do
    it 'is valid with valid attributes' do
      expect(FactoryBot.build(:challenge)).to be_valid
    end
  end

  describe 'invitation token' do
    describe 'callbacks' do
      it 'generates an invitation token before creation' do
        challenge = FactoryBot.build(:challenge, invitation_token: nil)
        expect(challenge.invitation_token).to be_nil
        challenge.save!
        expect(challenge.invitation_token).to be_present
        expect(challenge.invitation_token.length).to eq(6)
      end

      it 'generates unique invitation tokens' do
        challenge1 = FactoryBot.create(:challenge)
        challenge2 = FactoryBot.create(:challenge)
        expect(challenge1.invitation_token).not_to eq(challenge2.invitation_token)
      end
    end

    describe '#generate_invitation_token' do
      let(:challenge) { FactoryBot.build(:challenge) }

      it 'generates a 6-character alphanumeric token' do
        challenge.generate_invitation_token
        expect(challenge.invitation_token).to match(/\A[a-zA-Z0-9]{6}\z/)
      end

      it 'ensures token uniqueness' do
        existing_challenge = FactoryBot.create(:challenge)
        allow(SecureRandom).to receive(:alphanumeric).and_return(existing_challenge.invitation_token, 'ABC123')

        challenge.generate_invitation_token
        expect(challenge.invitation_token).to eq('ABC123')
      end
    end

    describe '#regenerate_invitation_token!' do
      let(:challenge) { FactoryBot.create(:challenge) }

      it 'generates a new token and saves the challenge' do
        original_token = challenge.invitation_token
        challenge.regenerate_invitation_token!
        expect(challenge.invitation_token).not_to eq(original_token)
        expect(challenge.reload.invitation_token).not_to eq(original_token)
      end
    end
  end

  describe '#owned_by?' do
    let(:creator) { create(:user) }
    let(:challenge) { create(:challenge, creator: creator) }
    let(:other_user) { create(:user) }

    it 'returns true for the creator' do
      expect(challenge.owned_by?(creator)).to be true
    end

    it 'returns false for another user' do
      expect(challenge.owned_by?(other_user)).to be false
    end

    it 'returns false for nil' do
      expect(challenge.owned_by?(nil)).to be false
    end
  end

  describe '#challenge_organizer?' do
    let(:creator) { create(:user) }
    let(:challenge) { create(:challenge, creator: creator) }
    let(:organizer_user) { create(:user) }
    let(:member_user) { create(:user) }

    before do
      create(:user_challenge_enrollment, :organizer, user: organizer_user, challenge: challenge)
      create(:user_challenge_enrollment, user: member_user, challenge: challenge)
    end

    it 'returns true for an organizer-enrolled user' do
      expect(challenge.challenge_organizer?(organizer_user)).to be true
    end

    it 'returns false for a member-enrolled user' do
      expect(challenge.challenge_organizer?(member_user)).to be false
    end

    it 'returns false for nil' do
      expect(challenge.challenge_organizer?(nil)).to be false
    end
  end

  describe '#manageable_by?' do
    let(:creator) { create(:user) }
    let(:challenge) { create(:challenge, creator: creator) }
    let(:organizer_user) { create(:user) }
    let(:member_user) { create(:user) }
    let(:outsider) { create(:user) }

    before do
      create(:user_challenge_enrollment, :organizer, user: organizer_user, challenge: challenge)
      create(:user_challenge_enrollment, user: member_user, challenge: challenge)
    end

    it 'returns true for the creator' do
      expect(challenge.manageable_by?(creator)).to be true
    end

    it 'returns true for a challenge organizer' do
      expect(challenge.manageable_by?(organizer_user)).to be true
    end

    it 'returns true for a site admin' do
      site_admin = create(:user, admin: true)
      expect(challenge.manageable_by?(site_admin)).to be true
    end

    it 'returns false for a regular member' do
      expect(challenge.manageable_by?(member_user)).to be false
    end

    it 'returns false for an outsider' do
      expect(challenge.manageable_by?(outsider)).to be false
    end

    it 'returns false for nil' do
      expect(challenge.manageable_by?(nil)).to be false
    end
  end

  describe '#owner_or_site_admin?' do
    let(:creator) { create(:user) }
    let(:challenge) { create(:challenge, creator: creator) }
    let(:organizer) { create(:user) }
    let(:member) { create(:user) }
    let(:outsider) { create(:user) }
    let(:site_admin) { create(:user, admin: true) }

    before do
      create(:user_challenge_enrollment, :organizer, user: organizer, challenge: challenge)
      create(:user_challenge_enrollment, user: member, challenge: challenge)
    end

    it 'returns true for the creator' do
      expect(challenge.owner_or_site_admin?(creator)).to be true
    end

    it 'returns true for a site admin' do
      expect(challenge.owner_or_site_admin?(site_admin)).to be true
    end

    it 'returns false for a challenge organizer (not owner or site admin)' do
      expect(challenge.owner_or_site_admin?(organizer)).to be false
    end

    it 'returns false for a plain member' do
      expect(challenge.owner_or_site_admin?(member)).to be false
    end

    it 'returns false for an outsider' do
      expect(challenge.owner_or_site_admin?(outsider)).to be false
    end

    it 'returns false for nil' do
      expect(challenge.owner_or_site_admin?(nil)).to be false
    end
  end

  describe 'deletion' do
    let(:creator) { FactoryBot.create(:user, admin: true) }
    let(:challenge) { FactoryBot.create(:challenge, creator: creator) }
    let(:other_user) { FactoryBot.create(:user) }

    before do
      # Create related records
      @enrollment = FactoryBot.create(:user_challenge_enrollment, challenge: challenge, user: other_user)
      @reading = FactoryBot.create(:reading, challenge: challenge)
      @group = FactoryBot.create(:group, challenge: challenge)
      @user_reading = FactoryBot.create(:user_reading, user: other_user, reading: @reading)
    end

    it 'destroys all associated records when deleted' do
      challenge_id = challenge.id

      expect { challenge.destroy }
        .to change(Challenge, :count).by(-1)
        .and change(UserChallengeEnrollment, :count).by(-1)
        .and change(Reading, :count).by(-1)
        .and change(Group, :count).by(-1)
        .and change(UserReading, :count).by(-1)
    end

    it 'does not destroy users when challenge is deleted' do
      expect { challenge.destroy }.not_to change(User, :count)
    end
  end

  describe '#daily_reading_status' do
    let(:user) { create(:user) }
    let(:challenge) { create(:challenge, timezone: 'UTC', start_date: 1.week.ago, end_date: 1.week.from_now) }
    let(:today) { Date.current }

    it 'returns unread status when chapters are scheduled today and user has not read' do
      reading = create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: today)
      status = challenge.daily_reading_status(user)

      expect(status[:has_reading]).to be true
      expect(status[:read_today]).to be false
      expect(status[:read_count]).to eq(0)
      expect(status[:total_count]).to eq(1)
      expect(status[:reading_title]).to eq("Matthew 1")
    end

    it 'returns read status when user completes all chapters today' do
      reading1 = create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: today)
      reading2 = create(:reading, challenge: challenge, book_number: 40, chapter_number: 2, scheduled_date: today)
      create(:user_reading, user: user, reading: reading1)
      create(:user_reading, user: user, reading: reading2)

      status = challenge.daily_reading_status(user)

      expect(status[:has_reading]).to be true
      expect(status[:read_today]).to be true
      expect(status[:read_count]).to eq(2)
      expect(status[:total_count]).to eq(2)
      expect(status[:reading_title]).to eq("2 chapters")
    end

    it 'returns rest day status when no readings are scheduled today' do
      status = challenge.daily_reading_status(user)

      expect(status[:has_reading]).to be false
      expect(status[:read_today]).to be false
      expect(status[:read_count]).to eq(0)
    end
  end
end
