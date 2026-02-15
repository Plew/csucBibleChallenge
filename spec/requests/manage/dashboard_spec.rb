require 'rails_helper'

RSpec.describe "Manage::Dashboard", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  describe "GET /challenges/:challenge_id/manage" do
    context "when logged in as the challenge owner" do
      before { login_via_session(owner) }

      it "returns success" do
        get challenge_manage_dashboard_path(challenge)
        expect(response).to have_http_status(:success)
      end

      it "displays challenge title" do
        get challenge_manage_dashboard_path(challenge)
        expect(response.body).to include(challenge.title)
      end
    end

    context "when logged in as a different user" do
      let(:other_user) { create(:user) }
      before { login_via_session(other_user) }

      it "redirects with access denied" do
        get challenge_manage_dashboard_path(challenge)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get challenge_manage_dashboard_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
