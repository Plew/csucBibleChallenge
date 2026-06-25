require "rails_helper"

RSpec.describe "Api::V1::ChallengeParticipants", type: :request do
  let(:challenge) { create(:challenge) }
  let(:participant) { create(:user) }

  def auth_header(key)
    { "Authorization" => "Bearer #{key}" }
  end

  before do
    challenge.regenerate_api_key!
    create(:user_challenge_enrollment, user: participant, challenge: challenge)
  end

  describe "GET /api/v1/challenges/:challenge_id/participants/:id" do
    it "returns 401 without a key" do
      get api_v1_challenge_participant_path(challenge, participant)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the participant graph with a valid key" do
      reading = create(:reading, challenge: challenge, book_number: 43, chapter_number: 3)
      create(:user_reading, user: participant, reading: reading, completed_on: Date.current)
      create(:verse_like, reading: reading, user: participant, verse_number: 16)

      get api_v1_challenge_participant_path(challenge, participant), headers: auth_header(challenge.api_key)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("participant", "user_id")).to eq(participant.id)
      expect(body).to include("reading_history", "groups", "likes", "comments", "stats")
      expect(body["likes"].first["reference"]).to eq("John 3:16")
    end

    it "returns 404 for a user not enrolled in this challenge" do
      stranger = create(:user)
      get api_v1_challenge_participant_path(challenge, stranger), headers: auth_header(challenge.api_key)
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a key belonging to a different challenge (403)" do
      other = create(:challenge)
      other.regenerate_api_key!
      get api_v1_challenge_participant_path(challenge, participant), headers: auth_header(other.api_key)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
