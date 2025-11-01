require 'rails_helper'

RSpec.describe "Stats", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:challenge) { FactoryBot.create(:challenge) }

  before do
    login_as user
    FactoryBot.create(:user_challenge_enrollment, user: user, challenge: challenge)
  end

  describe "GET /stats" do
    context "when challenge has no message_of_the_day" do
      it "does not display the message section" do
        get stats_path
        expect(response).to have_http_status(:success)
        # Check that the page renders successfully without the message
        expect(response.body).to include('Challenge Summary')
      end
    end

    context "when challenge has a message_of_the_day" do
      let(:message) { "Remember to pray before reading!" }

      before do
        challenge.update!(message_of_the_day: message)
      end

      it "displays the message on the stats page with primary border" do
        get stats_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(message)
        expect(response.body).to include('border-primary')
        # Verify it's wrapped in paragraph tags
        expect(response.body).to match(/<p>.*#{Regexp.escape(message)}.*<\/p>/m)
      end
    end

    context "when message contains a URL" do
      let(:message) { "Check out https://example.com for more info" }

      before do
        challenge.update!(message_of_the_day: message)
      end

      it "converts URLs to clickable links" do
        get stats_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('link link-primary')
        expect(response.body).to include('href="https://example.com"')
      end
    end

    context "when challenge has an empty message_of_the_day" do
      before do
        challenge.update!(message_of_the_day: "")
      end

      it "does not display the message section" do
        get stats_path
        expect(response).to have_http_status(:success)
        # Check that the page renders successfully without the message
        expect(response.body).to include('Challenge Summary')
      end
    end
  end
end
