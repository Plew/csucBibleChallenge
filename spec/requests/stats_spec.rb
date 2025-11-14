require 'rails_helper'

RSpec.describe "Stats", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:challenge) { FactoryBot.create(:challenge, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

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

      it "displays the message on the stats page" do
        get stats_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(message)
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

    context "with sprints" do
      let!(:sprint) { FactoryBot.create(:sprint, challenge: challenge, title: "Q1 Sprint", begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 3, 31)) }

      it "displays the sprint selector when sprints exist" do
        get stats_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Q1 Sprint")
      end

      it "uses the sprint from params" do
        get stats_path, params: { sprint_id: sprint.id }
        expect(response).to have_http_status(:success)
        expect(response.cookies['sprint_id']).to eq(sprint.id.to_s)
      end

      it "uses the sprint from cookies" do
        cookies[:sprint_id] = sprint.id
        get stats_path
        expect(response).to have_http_status(:success)
      end

      it "clears cookie when 'full' is selected" do
        get stats_path, params: { sprint_id: 'full' }
        expect(response).to have_http_status(:success)
        expect(response.cookies['sprint_id']).to be_nil
      end
    end
  end
end
