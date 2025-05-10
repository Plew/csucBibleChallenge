require 'rails_helper'

RSpec.describe "Api::V1::ChallengeEnrollments", type: :request do
  let!(:challenge) { FactoryBot.create(:challenge) }
  let!(:user) { FactoryBot.create(:user) }

  describe "POST /api/v1/challenges/:challenge_id/enrollments" do
    context "with valid parameters" do
      let(:valid_params) { { enrollment: { user_id: user.id } } }

      it "enrolls the user in the challenge" do
        expect {
          post "/api/v1/challenges/#{challenge.id}/enrollments", params: valid_params
        }.to change(UserChallengeEnrollment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["user_id"]).to eq(user.id)
        expect(JSON.parse(response.body)["challenge_id"]).to eq(challenge.id)
      end
    end

    context "when user is already enrolled" do
      before do
        FactoryBot.create(:user_challenge_enrollment, user: user, challenge: challenge)
      end
      let(:valid_params) { { enrollment: { user_id: user.id } } }

      it "does not create a new enrollment" do
        expect {
          post "/api/v1/challenges/#{challenge.id}/enrollments", params: valid_params
        }.not_to change(UserChallengeEnrollment, :count)
      end

      it "returns an unprocessable_entity status" do
        post "/api/v1/challenges/#{challenge.id}/enrollments", params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("User already enrolled in this challenge")
      end
    end

    context "with an invalid user_id" do
      let(:invalid_params) { { enrollment: { user_id: 9999 } } } # Non-existent user

      it "does not create an enrollment" do
        expect {
          post "/api/v1/challenges/#{challenge.id}/enrollments", params: invalid_params
        }.not_to change(UserChallengeEnrollment, :count)
      end

      it "returns an unprocessable_entity status" do # due to foreign key constraint or user must exist validation
        post "/api/v1/challenges/#{challenge.id}/enrollments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("User must exist")
      end
    end

    context "with a non-existent challenge_id" do
      let(:valid_params) { { enrollment: { user_id: user.id } } }
      it "returns a not_found status" do
        post "/api/v1/challenges/9999/enrollments", params: valid_params
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Couldn't find Challenge with 'id'=9999")
      end
    end
  end
end
