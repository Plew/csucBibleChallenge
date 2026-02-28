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

  describe "GET /challenges/:id/summary" do
    let!(:challenge) { create(:challenge) }

    it "returns http success" do
      get summary_challenge_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end
end
