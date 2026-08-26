require 'rails_helper'

RSpec.describe SendDailyReadingEmailsJob, type: :job do
  before do
    ActionMailer::Base.default_url_options[:host] = 'test.host'
  end

  describe '#perform' do
    let(:berlin_timezone) { 'Berlin' }
    let(:tokyo_timezone) { 'Tokyo' }

    let!(:user_with_email) { create(:user, daily_email: true) }
    let!(:user_without_email) { create(:user, daily_email: false) }

    let!(:berlin_challenge) do
      create(:challenge,
        timezone: berlin_timezone,
        start_date: 1.week.ago,
        end_date: 1.week.from_now
      )
    end

    let!(:tokyo_challenge) do
      create(:challenge,
        timezone: tokyo_timezone,
        start_date: 1.week.ago,
        end_date: 1.week.from_now
      )
    end

    let!(:completed_challenge) do
      create(:challenge,
        timezone: berlin_timezone,
        start_date: 2.weeks.ago,
        end_date: 1.day.ago
      )
    end

    before do
      create(:user_challenge_enrollment, user: user_with_email, challenge: berlin_challenge)
      create(:user_challenge_enrollment, user: user_without_email, challenge: berlin_challenge)
      create(:user_challenge_enrollment, user: user_with_email, challenge: tokyo_challenge)

      ActionMailer::Base.deliveries.clear
    end

    context 'when it is 6am in the challenge timezone' do
      let!(:berlin_reading) { create(:reading, challenge: berlin_challenge, scheduled_date: Date.current) }

      around do |example|
        berlin_6am = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        travel_to(berlin_6am) { example.run }
      end

      it 'sends emails to users who want daily emails' do
        expect {
          described_class.perform_now
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'does not send emails to users who opted out' do
        described_class.perform_now

        delivered_emails = ActionMailer::Base.deliveries
        recipient_emails = delivered_emails.map(&:to).flatten

        expect(recipient_emails).to include(user_with_email.email)
        expect(recipient_emails).not_to include(user_without_email.email)
      end

      it 'creates email login tokens for sent emails' do
        expect {
          described_class.perform_now
        }.to change { EmailLoginToken.count }.by(1)

        token = EmailLoginToken.last
        expect(token.user).to eq(user_with_email)
        expect(token.challenge).to eq(berlin_challenge)
        expect(token.reading).to eq(berlin_reading)
        expect(token.sent_at).to be_present
      end

      it 'sends emails with correct subject' do
        described_class.perform_now

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to match(/Bible Reading:/)
      end

      context 'when challenge has 4 chapters scheduled today' do
        let!(:reading2) { create(:reading, challenge: berlin_challenge, book_number: 40, chapter_number: 2, scheduled_date: Date.current) }
        let!(:reading3) { create(:reading, challenge: berlin_challenge, book_number: 40, chapter_number: 3, scheduled_date: Date.current) }
        let!(:reading4) { create(:reading, challenge: berlin_challenge, book_number: 40, chapter_number: 4, scheduled_date: Date.current) }

        it 'sends exactly ONE email containing all 4 chapters' do
          expect {
            described_class.perform_now
          }.to change { ActionMailer::Base.deliveries.count }.by(1)

          email = ActionMailer::Base.deliveries.last
          expect(email.subject).to include("Matthew 1, Matthew 2, Matthew 3, Matthew 4")
          expect(email.body.encoded).to include("Matthew 1, Matthew 2, Matthew 3, Matthew 4")
        end
      end
    end

    context 'when it is not 6am in the challenge timezone' do
      around do |example|
        berlin_8am = Time.current.in_time_zone(berlin_timezone).change(hour: 8, min: 0)
        travel_to(berlin_8am) { example.run }
      end

      it 'does not send any emails' do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not create any email login tokens' do
        expect {
          described_class.perform_now
        }.not_to change { EmailLoginToken.count }
      end
    end

    context 'when there is no reading scheduled for today' do
      around do |example|
        berlin_6am = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        travel_to(berlin_6am) { example.run }
      end

      it 'does not send any emails' do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with completed challenges' do
      around do |example|
        berlin_6am = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        travel_to(berlin_6am) { example.run }
      end

      it 'does not send emails for completed challenges' do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'duplicate guard on re-run' do
      let!(:berlin_reading) { create(:reading, challenge: berlin_challenge, scheduled_date: Date.current) }

      around do |example|
        berlin_6am = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        travel_to(berlin_6am) { example.run }
      end

      it 'does not send duplicate emails on re-run' do
        described_class.perform_now
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        ActionMailer::Base.deliveries.clear

        # Run again — should not send because token already exists
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not create duplicate tokens on re-run' do
        described_class.perform_now
        initial_count = EmailLoginToken.count

        described_class.perform_now
        expect(EmailLoginToken.count).to eq(initial_count)
      end
    end

    context 'different timezone challenges at different times' do
      it 'sends for Berlin challenge at 6am Berlin time but not Tokyo' do
        # Freeze to 6am Berlin time, compute the Berlin date, then create the reading
        berlin_6am = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)

        travel_to(berlin_6am) do
          berlin_date = berlin_6am.to_date
          create(:reading, challenge: berlin_challenge, scheduled_date: berlin_date)
          create(:reading, challenge: tokyo_challenge, scheduled_date: berlin_date)

          described_class.perform_now

          delivered_to_challenges = EmailLoginToken.pluck(:challenge_id)
          expect(delivered_to_challenges).to include(berlin_challenge.id)
          expect(delivered_to_challenges).not_to include(tokyo_challenge.id)
        end
      end

      it 'sends for Tokyo challenge at 6am Tokyo time but not Berlin' do
        # Freeze to 6am Tokyo time, compute the Tokyo date, then create the reading
        tokyo_6am = Time.current.in_time_zone(tokyo_timezone).change(hour: 6, min: 0)

        travel_to(tokyo_6am) do
          tokyo_date = tokyo_6am.to_date
          create(:reading, challenge: berlin_challenge, scheduled_date: tokyo_date)
          create(:reading, challenge: tokyo_challenge, scheduled_date: tokyo_date)

          described_class.perform_now

          delivered_to_challenges = EmailLoginToken.pluck(:challenge_id)
          expect(delivered_to_challenges).to include(tokyo_challenge.id)
          expect(delivered_to_challenges).not_to include(berlin_challenge.id)
        end
      end
    end
  end
end
