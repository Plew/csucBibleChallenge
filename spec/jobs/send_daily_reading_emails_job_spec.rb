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

      before do
        # Mock current time to be 6am in Berlin timezone
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))
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
    end

    context 'when it is not 6am in the challenge timezone' do
      before do
        # Mock current time to be 8am in Berlin timezone
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 8, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))
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
      before do
        # Mock current time to be 6am in Berlin timezone
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))
      end

      it 'does not send any emails' do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with completed challenges' do
      before do
        # Mock current time to be 6am in Berlin timezone
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))
      end

      it 'does not send emails for completed challenges' do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'duplicate guard on re-run' do
      let!(:berlin_reading) { create(:reading, challenge: berlin_challenge, scheduled_date: Date.current) }

      before do
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))
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
      let!(:berlin_reading) { create(:reading, challenge: berlin_challenge, scheduled_date: Date.current) }
      let!(:tokyo_reading) { create(:reading, challenge: tokyo_challenge, scheduled_date: Date.current) }

      it 'sends for Berlin challenge at 6am Berlin time but not Tokyo' do
        # 6am Berlin is ~2pm Tokyo (UTC+9 vs UTC+1/+2)
        berlin_time = Time.current.in_time_zone(berlin_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(berlin_time.in_time_zone('UTC'))

        described_class.perform_now

        delivered_to_challenges = EmailLoginToken.pluck(:challenge_id)
        expect(delivered_to_challenges).to include(berlin_challenge.id)
        expect(delivered_to_challenges).not_to include(tokyo_challenge.id)
      end

      it 'sends for Tokyo challenge at 6am Tokyo time but not Berlin' do
        # 6am Tokyo is ~10pm Berlin (previous day)
        tokyo_time = Time.current.in_time_zone(tokyo_timezone).change(hour: 6, min: 0)
        allow(Time).to receive(:current).and_return(tokyo_time.in_time_zone('UTC'))

        described_class.perform_now

        delivered_to_challenges = EmailLoginToken.pluck(:challenge_id)
        expect(delivered_to_challenges).to include(tokyo_challenge.id)
        # Berlin would be around 10pm-11pm, not 6am
        expect(delivered_to_challenges).not_to include(berlin_challenge.id)
      end
    end
  end
end
