require 'rails_helper'

RSpec.describe "Manage::Danger", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  describe "GET /challenges/:challenge_id/manage/danger" do
    context "as the challenge owner" do
      before { login_via_session(owner) }

      it "returns success" do
        get challenge_manage_danger_path(challenge)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a site admin who is not the owner" do
      let(:admin_user) { create(:user, :admin) }
      before { login_via_session(admin_user) }

      it "returns success" do
        get challenge_manage_danger_path(challenge)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a challenge admin who is not the owner" do
      let(:organizer) { create(:user) }
      before do
        create(:user_challenge_enrollment, :admin, user: organizer, challenge: challenge)
        login_via_session(organizer)
      end

      it "redirects to the console overview (not allowed to delete)" do
        get challenge_manage_danger_path(challenge)
        expect(response).to redirect_to(challenge_manage_dashboard_path(challenge))
      end
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/danger" do
    before { login_via_session(owner) }

    context "with the correct confirmation text" do
      it "destroys the challenge and redirects home" do
        challenge
        expect {
          delete challenge_manage_danger_path(challenge), params: { confirmation_text: "i want this" }
        }.to change(Challenge, :count).by(-1)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with incorrect confirmation text" do
      it "does not destroy the challenge" do
        challenge
        expect {
          delete challenge_manage_danger_path(challenge), params: { confirmation_text: "nope" }
        }.not_to change(Challenge, :count)
        expect(response).to redirect_to(challenge_manage_danger_path(challenge))
      end
    end
  end
end
