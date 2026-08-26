require 'rails_helper'

RSpec.describe "Challenges", type: :request do
  describe "GET /challenges" do
    let!(:visible_challenge) { create(:challenge, title: "Visible Challenge", hidden: false, start_date: Date.current, end_date: Date.current + 30.days) }
    let!(:hidden_challenge) { create(:challenge, title: "Hidden Challenge", hidden: true, start_date: Date.current, end_date: Date.current + 30.days) }
    let!(:past_challenge) { create(:challenge, title: "Past Challenge", hidden: false, start_date: Date.current - 60.days, end_date: Date.current - 30.days) }

    it "returns http success" do
      get challenges_path
      expect(response).to have_http_status(:success)
    end

    it "displays only visible and active challenges" do
      get challenges_path
      expect(response.body).to include("Visible Challenge")
      expect(response.body).not_to include("Hidden Challenge")
      expect(response.body).not_to include("Past Challenge")
    end

    it "does not display hidden challenges even if they are active" do
      get challenges_path
      expect(response.body).not_to include("Hidden Challenge")
    end
  end

  describe "GET /challenges/:id" do
    let(:challenge) { create(:challenge) }

    it "returns http success" do
      get challenge_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays challenge details" do
      get challenge_path(challenge)
      expect(response.body).to include(challenge.title)
    end

    it "allows accessing hidden challenges directly by ID" do
      hidden_challenge = create(:challenge, title: "Hidden Challenge", hidden: true)
      get challenge_path(hidden_challenge)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Hidden Challenge")
    end
  end

  describe "GET /challenges/new" do
    let(:user) { create(:user, can_create_challenges: true) }

    before do
      post user_session_path, params: { session: { email: user.email, password: "password123" } }
    end

    it "renders both Old Testament and New Testament book options" do
      get new_challenge_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Old Testament")
      expect(response.body).to include("New Testament")
      expect(response.body).to include("Genesis")
      expect(response.body).to include("Psalms")
      expect(response.body).to include("Matthew")
    end
  end

  describe "POST /challenges with Old Testament books" do
    let(:user) { create(:user, can_create_challenges: true) }

    before do
      post user_session_path, params: { session: { email: user.email, password: "password123" } }
    end

    it "creates readings for selected Old Testament books" do
      expect {
        post challenges_path, params: {
          challenge: {
            name: "Genesis Challenge",
            description: "Read Genesis",
            start_date: Date.current.to_s,
            timezone: "Eastern Time (US & Canada)",
            chapters_per_day: 1
          },
          selected_books: ["1"] # Genesis (book 1, 50 chapters)
        }
      }.to change(Challenge, :count).by(1)

      challenge = Challenge.last
      expect(challenge.readings.count).to eq(50)
      expect(challenge.readings.first.book_number).to eq(1)
      expect(challenge.readings.first.chapter_number).to eq(1)
      expect(challenge.readings.last.chapter_number).to eq(50)
    end
  end
end
