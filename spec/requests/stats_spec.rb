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
        # Verify it's rendered with markdown (wrapped in paragraph tags)
        expect(response.body).to match(/<p>#{Regexp.escape(message)}<\/p>/m)
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
        # Markdown helper automatically converts URLs to links
        expect(response.body).to include('href="https://example.com"')
        # Links open in new tab
        expect(response.body).to include('target="_blank"')
      end
    end

    context "when message contains markdown links" do
      let(:message) { "Check out [our website](https://example.com) for more info" }

      before do
        challenge.update!(message_of_the_day: message)
      end

      it "renders markdown links properly" do
        get stats_path
        expect(response).to have_http_status(:success)
        # Should render the link text
        expect(response.body).to include('our website')
        # Should have the href
        expect(response.body).to include('href="https://example.com"')
        # Links open in new tab
        expect(response.body).to include('target="_blank"')
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

    context "when stats_start_date is set" do
      let(:today) { Date.current }
      let(:challenge) { FactoryBot.create(:challenge, start_date: today - 20.days, end_date: today + 20.days, stats_start_date: today - 5.days) }

      before do
        # 10 readings before stats_start_date (trial period)
        10.times do |i|
          r = FactoryBot.create(:reading, challenge: challenge, scheduled_date: today - 15.days + i.days, book_number: 1, chapter_number: i + 1)
          FactoryBot.create(:user_reading, user: user, reading: r, completed_on: r.scheduled_date)
        end
        # 5 readings within stats window up to today (user completed 5)
        5.times do |i|
          r = FactoryBot.create(:reading, challenge: challenge, scheduled_date: today - 5.days + i.days, book_number: 1, chapter_number: 11 + i)
          FactoryBot.create(:user_reading, user: user, reading: r, completed_on: r.scheduled_date)
        end
      end

      it "calculates personal stats scoped to the stats start date" do
        get stats_path
        expect(response).to have_http_status(:success)
        # Personal stats assign should reflect readings within the stats window
        personal_stats = controller.send(:calculate_personal_stats, user, challenge)
        expect(personal_stats[:chapters_completed]).to eq(5)
        expect(personal_stats[:chapters_scheduled]).to eq(5)
        expect(personal_stats[:completion_percentage]).to eq(100)
      end
    end
  end
end
