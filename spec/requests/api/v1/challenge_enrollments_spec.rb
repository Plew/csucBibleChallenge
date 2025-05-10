require 'rails_helper'

RSpec.describe "Api::V1::ChallengeEnrollments", type: :request do
  let!(:challenge) { FactoryBot.create(:challenge) }
  let!(:user) { FactoryBot.create(:user) }
  let!(:group) { FactoryBot.create(:group, challenge: challenge) }

  describe "POST /api/v1/challenges/:challenge_id/enrollments" do
    context "with valid parameters (no group_id)" do
      let(:valid_params) { { enrollment: { user_id: user.id } } }

      it "enrolls the user in the challenge without a group" do
        expect {
          post "/api/v1/challenges/#{challenge.id}/enrollments", params: valid_params
        }.to change(UserChallengeEnrollment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json["user_id"]).to eq(user.id)
        expect(json["challenge_id"]).to eq(challenge.id)
        expect(json["group_id"]).to be_nil
      end
    end

    context "with valid parameters (with group_id)" do
      let(:valid_params_with_group) { { enrollment: { user_id: user.id, group_id: group.id } } }

      it "enrolls the user in the challenge with a group" do
        expect {
          post "/api/v1/challenges/#{challenge.id}/enrollments", params: valid_params_with_group
        }.to change(UserChallengeEnrollment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json["group_id"]).to eq(group.id)
      end

      it "fails if group_id does not belong to the challenge" do
        other_challenge = FactoryBot.create(:challenge)
        other_group = FactoryBot.create(:group, challenge: other_challenge)
        invalid_params = { enrollment: { user_id: user.id, group_id: other_group.id } }
        post "/api/v1/challenges/#{challenge.id}/enrollments", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        # This error is now caught by the controller logic before model save
        # expect(json["errors"]).to include("Group must belong to the same challenge") 
        # Actually, the UserChallengeEnrollment.new will not raise for this, it will simply not save if there's a model validation.
        # The controller should prevent this. Let's check the error message from the controller directly.
        expect(json["errors"]).to include("Group must belong to the same challenge")
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

  describe "PATCH /api/v1/challenges/:challenge_id/enrollments/:id" do
    let!(:enrollment) { FactoryBot.create(:user_challenge_enrollment, user: user, challenge: challenge, group: nil) }
    let!(:new_group) { FactoryBot.create(:group, challenge: challenge, name: "New Test Group") }

    context "with valid group_id" do
      it "updates the enrollment with the new group_id" do
        patch "/api/v1/challenges/#{challenge.id}/enrollments/#{enrollment.id}", params: { enrollment: { group_id: new_group.id } }
        expect(response).to have_http_status(:ok)
        expect(json["group_id"]).to eq(new_group.id)
        expect(enrollment.reload.group_id).to eq(new_group.id)
      end
    end

    context "setting group_id to nil (leaving group)" do
      let!(:enrollment_in_group) { FactoryBot.create(:user_challenge_enrollment, user: FactoryBot.create(:user), challenge: challenge, group: group) }
      it "updates the enrollment group_id to nil" do
        patch "/api/v1/challenges/#{challenge.id}/enrollments/#{enrollment_in_group.id}", params: { enrollment: { group_id: nil } }
        expect(response).to have_http_status(:ok)
        expect(json["group_id"]).to be_nil
        expect(enrollment_in_group.reload.group_id).to be_nil
      end
    end

    context "with invalid group_id (group does not belong to challenge)" do
      let!(:other_challenge_group) { FactoryBot.create(:group) } # Belongs to a different challenge
      it "does not update the enrollment and returns an error" do
        patch "/api/v1/challenges/#{challenge.id}/enrollments/#{enrollment.id}", params: { enrollment: { group_id: other_challenge_group.id } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to include("Group must belong to the same challenge")
        expect(enrollment.reload.group_id).to be_nil
      end
    end

    context "when enrollment does not exist" do
      it "returns a not_found status" do
        patch "/api/v1/challenges/#{challenge.id}/enrollments/9999", params: { enrollment: { group_id: new_group.id } }
        expect(response).to have_http_status(:not_found) # Error from set_enrollment via base_controller rescue
      end
    end
  end

  # Helper method to parse JSON responses
  def json
    JSON.parse(response.body)
  end
end
