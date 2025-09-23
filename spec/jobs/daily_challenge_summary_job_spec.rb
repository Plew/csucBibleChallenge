require 'rails_helper'

RSpec.describe DailyChallengeSummaryJob, type: :job do
  describe '#perform' do
    let(:creator1) { create(:user) }
    let(:creator2) { create(:user) }
    let(:participant) { create(:user) }
    
    let!(:active_challenge) do
      create(:challenge, 
        creator: creator1,
        start_date: 1.week.ago,
        end_date: 1.week.from_now
      )
    end
    
    let!(:completed_challenge) do
      create(:challenge,
        creator: creator2,
        start_date: 2.weeks.ago,
        end_date: 1.day.ago
      )
    end
    
    let!(:future_challenge) do
      create(:challenge,
        creator: creator1,
        start_date: 1.week.from_now,
        end_date: 2.weeks.from_now
      )
    end

    before do
      create(:user_challenge_enrollment, user: participant, challenge: active_challenge)
      create(:user_challenge_enrollment, user: participant, challenge: completed_challenge)
      create(:user_challenge_enrollment, user: participant, challenge: future_challenge)
    end

    it 'sends emails only for active challenges' do
      expect {
        described_class.perform_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(creator1.email)
      expect(email.subject).to include(active_challenge.name)
    end

    it 'does not send emails for completed or future challenges' do
      # Clear any existing deliveries
      ActionMailer::Base.deliveries.clear
      
      described_class.perform_now
      
      delivered_emails = ActionMailer::Base.deliveries
      challenge_names = delivered_emails.map(&:subject).join(' ')
      
      expect(challenge_names).not_to include(completed_challenge.name)
      expect(challenge_names).not_to include(future_challenge.name)
    end
  end
end