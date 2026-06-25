require "rails_helper"

RSpec.describe "Api::V1::ChallengeSprints", type: :request do
  let(:challenge) do
    create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10)
  end
  let!(:sprint) do
    create(:sprint, challenge: challenge, title: "Week 1",
                    begin_date: Date.current - 7, end_date: Date.current - 1)
  end

  def auth_header(key)
    { "Authorization" => "Bearer #{key}" }
  end

  before { challenge.regenerate_api_key! }

  describe "GET /api/v1/challenges/:challenge_id/sprints" do
    it "returns 401 without a key" do
      get api_v1_challenge_sprints_path(challenge)
      expect(response).to have_http_status(:unauthorized)
    end

    it "lists the sprints with their dates and status" do
      get api_v1_challenge_sprints_path(challenge), headers: auth_header(challenge.api_key)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      row = body["sprints"].first
      expect(row).to include("title" => "Week 1", "status" => "past")
      expect(row["begin_date"]).to eq(sprint.begin_date.to_s)
      expect(row["end_date"]).to eq(sprint.end_date.to_s)
      expect(row).to include("winners", "winners_calculated")
    end
  end

  describe "GET /api/v1/challenges/:challenge_id/sprints/:id" do
    it "returns ranked standings with completion and on-schedule percentages" do
      reading = create(:reading, challenge: challenge, scheduled_date: Date.current - 4)
      member = create(:user)
      group = create(:group, challenge: challenge, name: "Lions")
      create(:user_group_enrollment, user: member, group: group)
      create(:user_reading, user: member, reading: reading, completed_on: reading.scheduled_date)

      get api_v1_challenge_sprint_path(challenge, sprint), headers: auth_header(challenge.api_key)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("sprint", "id")).to eq(sprint.id)
      standing = body["standings"].first
      expect(standing).to include("rank" => 1, "group_name" => "Lions")
      expect(standing).to include("completion_percentage", "on_schedule_percentage", "members")
    end

    it "returns 404 for a sprint in another challenge" do
      other_challenge = create(:challenge, start_date: Date.current - 10, end_date: Date.current + 10)
      other_sprint = create(:sprint, challenge: other_challenge,
                                     begin_date: Date.current - 7, end_date: Date.current - 1)
      get api_v1_challenge_sprint_path(challenge, other_sprint), headers: auth_header(challenge.api_key)
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a key belonging to a different challenge (403)" do
      other = create(:challenge)
      other.regenerate_api_key!
      get api_v1_challenge_sprint_path(challenge, sprint), headers: auth_header(other.api_key)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
