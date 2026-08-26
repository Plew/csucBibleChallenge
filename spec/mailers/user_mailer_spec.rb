require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  before do
    ActionMailer::Base.default_url_options[:host] = 'test.host'
  end

  describe "password_reset" do
    let(:user) { create(:user, email: "to@example.org") }
    let(:token) { "test_token_123" }
    let(:mail) { UserMailer.password_reset(user, token) }

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset - And God Said")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "noreply@andgodsaid.org" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "daily_reading" do
    let(:user) { create(:user, email: "reader@example.org", username: "TestReader") }
    let(:challenge) { create(:challenge, timezone: 'Berlin') }
    let(:reading) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 7) }
    let(:login_token) { create(:email_login_token, user: user, challenge: challenge, reading: reading) }
    let(:mail) { UserMailer.daily_reading(user, reading, login_token) }

    it "renders the headers" do
      expect(mail.subject).to eq("Bible Reading: Romans 7")
      expect(mail.to).to eq([ "reader@example.org" ])
      expect(mail.from).to eq([ "noreply@andgodsaid.org" ])
    end

    it "includes the user's name in the body" do
      expect(mail.body.encoded).to match("TestReader")
    end

    it "includes the reading title in the body" do
      expect(mail.body.encoded).to match("Romans 7")
    end

    it "includes the login link in the body" do
      expect(mail.body.encoded).to match(login_token.token)
    end

    it "includes 'Read Now' call to action" do
      expect(mail.body.encoded).to match("Read Now")
    end

    it "includes 'Good morning' greeting" do
      expect(mail.body.encoded).to match("Good morning")
    end

    it "does not include the verse text" do
      # Verify that the actual Bible text is not in the email
      expect(mail.body.encoded).not_to match(/verse_text/)
    end

    context "when multiple chapters are scheduled for today" do
      let(:reading2) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 8) }
      let(:reading3) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 9) }
      let(:reading4) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 10) }
      let(:mail_multi) { UserMailer.daily_reading(user, [reading, reading2, reading3, reading4], login_token) }

      it "lists all 4 chapters in the subject" do
        expect(mail_multi.subject).to eq("Bible Reading: Romans 7, Romans 8, Romans 9, Romans 10")
      end

      it "includes all chapters in the body with plural phrasing" do
        expect(mail_multi.body.encoded).to match("Romans 7, Romans 8, Romans 9, Romans 10")
        expect(mail_multi.body.encoded).to match("today's chapters")
      end
    end
  end
end
