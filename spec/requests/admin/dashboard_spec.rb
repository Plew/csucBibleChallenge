require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "when user is admin" do
    before { login_via_session(admin_user) }

    let!(:challenge1) { create(:challenge, title: "Challenge 1") }
    let!(:challenge2) { create(:challenge, title: "Challenge 2", hidden: true) }

    describe "GET /admin" do
      it "returns http success" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it "displays dashboard title" do
        get admin_root_path
        expect(response.body).to include("Admin Dashboard")
      end

      it "shows challenges count" do
        get admin_root_path
        expect(response.body).to include("2") # Total challenges including hidden
      end

      it "shows users count" do
        get admin_root_path
        # Total users = admin_user + regular_user = 2
        expect(response.body).to include("2")
      end

      it "provides navigation links" do
        get admin_root_path
        expect(response.body).to include(admin_challenges_path)
        expect(response.body).to include(admin_users_path)
        expect(response.body).to include("Manage Challenges")
        expect(response.body).to include("Manage Users")
      end

      it "has link back to main site" do
        get admin_root_path
        expect(response.body).to include("Back to Site")
        expect(response.body).to include(root_path)
      end
    end
  end
end
