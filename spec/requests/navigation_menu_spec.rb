require 'rails_helper'

RSpec.describe "Navigation Menu", type: :request do
  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "Admin link visibility" do
    context "when user is an admin" do
      let(:admin_user) { create(:user, :admin) }

      before do
        log_in_as(admin_user)
        follow_redirect!
      end

      it "shows the Admin link pointing to admin root" do
        expect(response.body).to include(I18n.t("navigation.admin"))
        expect(response.body).to include(admin_root_path)
      end

      it "does not show Manage Feedback separately" do
        expect(response.body).not_to include(I18n.t("navigation.manage_feedback"))
      end
    end

    context "when user owns a challenge (non-admin)" do
      let(:creator) { create(:user) }
      let!(:owned_challenge) { create(:challenge, creator: creator) }

      before do
        log_in_as(creator)
        follow_redirect!
      end

      it "does not show the challenge admin link on non-challenge pages" do
        expect(response.body).not_to include(I18n.t("navigation.challenge_admin"))
      end

      it "shows the challenge admin link on challenge-scoped pages" do
        get challenge_path(owned_challenge)
        expect(response.body).to include(I18n.t("navigation.challenge_admin"))
        expect(response.body).to include(challenge_manage_dashboard_path(owned_challenge))
      end
    end

    context "when user is a regular user" do
      let(:regular_user) { create(:user) }

      before do
        log_in_as(regular_user)
        follow_redirect!
      end

      it "does not show the Admin link in the menu" do
        expect(response.body).not_to include(">" + I18n.t("navigation.admin") + "</a>")
      end
    end

    context "when user is not logged in" do
      it "does not show the Admin link" do
        get root_path
        expect(response.body).not_to include(">" + I18n.t("navigation.admin") + "</a>")
      end
    end
  end
end
