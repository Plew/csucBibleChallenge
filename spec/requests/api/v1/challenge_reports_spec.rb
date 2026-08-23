require "rails_helper"

RSpec.describe "Api::V1::ChallengeReports", type: :request do
  let(:challenge)       { create(:challenge) }
  let(:other_challenge) { create(:challenge) }

  def auth_header(key)
    { "Authorization" => "Bearer #{key}" }
  end

  describe "GET /api/v1/challenges/:id/report" do
    it "returns 401 without a key" do
      get report_api_v1_challenge_path(challenge)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid key" do
      get report_api_v1_challenge_path(challenge), headers: auth_header("andgodsaidbc_not_a_real_key")
      expect(response).to have_http_status(:unauthorized)
    end

    context "with a valid key for this challenge" do
      before { challenge.regenerate_api_key! }

      it "returns the full report scoped to the challenge" do
        get report_api_v1_challenge_path(challenge), headers: auth_header(challenge.api_key)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.dig("challenge", "id")).to eq(challenge.id)
        expect(body).to include("stats", "readings", "participants", "groups", "top_liked_verses", "generated_at")
      end
    end

    it "rejects a key belonging to a different challenge (403)" do
      other_challenge.regenerate_api_key!
      get report_api_v1_challenge_path(challenge), headers: auth_header(other_challenge.api_key)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
