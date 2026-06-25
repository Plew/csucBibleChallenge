require "rails_helper"

RSpec.describe "Api::V1::GroupReports", type: :request do
  let(:challenge) { create(:challenge) }
  let(:group)     { create(:group, challenge: challenge, name: "Munich") }

  def auth_header(key)
    { "Authorization" => "Bearer #{key}" }
  end

  before { challenge.regenerate_api_key! }

  describe "GET /api/v1/challenges/:challenge_id/groups/:id/report" do
    it "returns 401 without a key" do
      get report_api_v1_challenge_group_path(challenge, group)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the group graph with a valid key" do
      member = create(:user, username: "alice")
      create(:user_challenge_enrollment, user: member, challenge: challenge)
      create(:user_group_enrollment, user: member, group: group)

      get report_api_v1_challenge_group_path(challenge, group), headers: auth_header(challenge.api_key)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("group", "name")).to eq("Munich")
      expect(body).to include("stats", "members", "sprints")
      expect(body["members"].first["username"]).to eq("alice")
    end

    it "returns 404 for a group in another challenge" do
      other_group = create(:group)
      get report_api_v1_challenge_group_path(challenge, other_group), headers: auth_header(challenge.api_key)
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a key belonging to a different challenge (403)" do
      other = create(:challenge)
      other.regenerate_api_key!
      get report_api_v1_challenge_group_path(challenge, group), headers: auth_header(other.api_key)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
