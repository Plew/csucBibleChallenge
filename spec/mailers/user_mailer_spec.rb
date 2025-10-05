require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "password_reset" do
    let(:user) { create(:user, email: "to@example.org") }
    let(:token) { "test_token_123" }
    let(:mail) { UserMailer.password_reset(user, token) }

    before do
      ActionMailer::Base.default_url_options[:host] = 'test.host'
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset - CSM Bible Challenge")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["noreply@mail.csmbiblechallenge.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
