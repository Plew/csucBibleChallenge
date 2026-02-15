require 'rails_helper'

RSpec.describe "Manage::Settings", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  before { login_via_session(owner) }

  describe "GET /challenges/:challenge_id/manage/settings/edit" do
    it "returns success" do
      get edit_challenge_manage_settings_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/settings" do
    context "with valid parameters" do
      it "updates the challenge" do
        patch challenge_manage_settings_path(challenge), params: { challenge: { name: "Updated Name" } }
        challenge.reload
        expect(challenge.name).to eq("Updated Name")
      end

      it "redirects to the dashboard" do
        patch challenge_manage_settings_path(challenge), params: { challenge: { name: "Updated Name" } }
        expect(response).to redirect_to(challenge_manage_dashboard_path(challenge))
      end
    end

    context "with invalid parameters" do
      it "renders the edit form" do
        patch challenge_manage_settings_path(challenge), params: { challenge: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { create(:user) }
    before { login_via_session(other_user) }

    it "denies access to edit" do
      get edit_challenge_manage_settings_path(challenge)
      expect(response).to redirect_to(root_path)
    end

    it "denies access to update" do
      patch challenge_manage_settings_path(challenge), params: { challenge: { name: "Hacked" } }
      expect(response).to redirect_to(root_path)
      challenge.reload
      expect(challenge.name).not_to eq("Hacked")
    end
  end
end
