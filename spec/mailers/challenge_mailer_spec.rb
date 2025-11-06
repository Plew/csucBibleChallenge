require "rails_helper"

RSpec.describe ChallengeMailer, type: :mailer do
  describe "daily_summary" do
    let(:creator) { create(:user, email: "creator@example.com") }
    let(:participant1) { create(:user, email: "participant1@example.com") }
    let(:participant2) { create(:user, email: "participant2@example.com") }
    let(:challenge) do
      create(:challenge,
        creator: creator,
        name: "Test Challenge",
        start_date: 1.week.ago,
        end_date: 1.week.from_now
      )
    end

    before do
      create(:user_challenge_enrollment, user: participant1, challenge: challenge)
      create(:user_challenge_enrollment, user: participant2, challenge: challenge)
    end

    let(:mail) { ChallengeMailer.daily_summary(challenge) }

    it "renders the headers" do
      expect(mail.subject).to eq("Daily Summary: Test Challenge")
      expect(mail.to).to eq([ "creator@example.com" ])
      expect(mail.from).to eq([ "noreply@mail.csmbiblechallenge.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Test Challenge")
      expect(mail.body.encoded).to match("participant1@example.com")
      expect(mail.body.encoded).to match("participant2@example.com")
      expect(mail.body.encoded).to match("Participants \\(2\\)")
    end

    it "includes challenge details" do
      expect(mail.body.encoded).to match(challenge.name)
      expect(mail.body.encoded).to match("daily summary for the challenge")
    end
  end
end
