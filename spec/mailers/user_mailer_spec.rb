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
    let(:user) { create(:user, email: "reader@example.org", username: "TestReader", version: "ESV") }
    let(:challenge) { create(:challenge, timezone: 'Berlin') }
    let(:reading) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 7) }
    let!(:verse1) { create(:verse, version: "ESV", book_number: 45, chapter_number: 7, verse_number: 1, verse_text: "Know ye not, brethren...") }
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

    it "includes 'Good morning' greeting" do
      expect(mail.body.encoded).to match("Good morning")
    end

    it "includes the chapter verse text in the email" do
      expect(mail.body.encoded).to match("Know ye not, brethren...")
    end

    it "includes the branded header" do
      expect(mail.body.encoded).to match("And God Said")
    end

    context "when multiple chapters are scheduled for today" do
      let(:reading2) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 8) }
      let(:reading3) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 9) }
      let(:reading4) { create(:reading, challenge: challenge, book_number: 45, chapter_number: 10) }
      let!(:verse_ch8) { create(:verse, version: "ESV", book_number: 45, chapter_number: 8, verse_number: 1, verse_text: "There is therefore now no condemnation...") }
      let(:mail_multi) { UserMailer.daily_reading(user, [ reading, reading2, reading3, reading4 ], login_token) }

      it "lists all 4 chapters in the subject" do
        expect(mail_multi.subject).to eq("Bible Reading: Romans 7, Romans 8, Romans 9, Romans 10")
      end

      it "includes all chapters in the body" do
        expect(mail_multi.body.encoded).to match("Romans 7")
        expect(mail_multi.body.encoded).to match("Romans 8")
        expect(mail_multi.body.encoded).to match("Romans 9")
        expect(mail_multi.body.encoded).to match("Romans 10")
        expect(mail_multi.body.encoded).to match("There is therefore now no condemnation...")
      end
    end

    context "when reading is an Old Testament chapter" do
      let(:ot_reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 17) }
      let!(:esv_ot_verse) { create(:verse, version: "ESV", book_number: 1, chapter_number: 17, verse_number: 1, verse_text: "When Abram was ninety-nine years old the LORD appeared to Abram") }
      let!(:german_ot_verse) { create(:verse, version: "ELB2006", book_number: 1, chapter_number: 17, verse_number: 1, verse_text: "Als nun Abram neunundneunzig Jahre alt war, erschien der HERR dem Abram") }
      let(:ot_login_token) { create(:email_login_token, user: user, challenge: challenge, reading: ot_reading) }

      it "sends English verses to an ESV user even when German verses exist" do
        mail = UserMailer.daily_reading(user, ot_reading, ot_login_token)
        expect(mail.body.encoded).to match("When Abram was ninety-nine years old")
        expect(mail.body.encoded).not_to match("neunundneunzig Jahre alt")
      end

      it "sends English verses to an RCV user for Old Testament readings if API is unavailable" do
        rcv_user = create(:user, email: "rcv_reader@example.org", username: "RcvReader", version: "RCV")
        rcv_token = create(:email_login_token, user: rcv_user, challenge: challenge, reading: ot_reading)
        allow_any_instance_of(RecoveryVersionClient).to receive(:fetch_chapter).and_return(nil)

        mail = UserMailer.daily_reading(rcv_user, ot_reading, rcv_token)
        expect(mail.body.encoded).to match("When Abram was ninety-nine years old")
        expect(mail.body.encoded).not_to match("neunundneunzig Jahre alt")
      end

      it "sends RCV verses to an RCV user when LSM API succeeds" do
        rcv_user = create(:user, email: "rcv_reader2@example.org", username: "RcvReader2", version: "RCV")
        rcv_token = create(:email_login_token, user: rcv_user, challenge: challenge, reading: ot_reading)
        allow_any_instance_of(RecoveryVersionClient).to receive(:fetch_chapter).and_return([
          OpenStruct.new(verse_number: 1, verse_text: "And when Abram was ninety-nine years old, Jehovah appeared to Abram")
        ])

        mail = UserMailer.daily_reading(rcv_user, ot_reading, rcv_token)
        expect(mail.body.encoded).to match("Jehovah appeared to Abram")
        expect(mail.body.encoded).to match("RCV")
      end

      it "sends German verses to a user who explicitly selected German (ELB2006)" do
        german_user = create(:user, email: "german_reader@example.org", username: "GermanReader", version: "ELB2006")
        german_token = create(:email_login_token, user: german_user, challenge: challenge, reading: ot_reading)

        mail = UserMailer.daily_reading(german_user, ot_reading, german_token)
        expect(mail.body.encoded).to match("Als nun Abram neunundneunzig Jahre alt war")
      end
    end
  end
end
