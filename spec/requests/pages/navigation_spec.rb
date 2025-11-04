require 'rails_helper'

RSpec.describe "Page Navigation with Realistic Data", type: :request do
  # Include the shared context that creates realistic challenge data
  include_context 'realistic challenge'

  describe "logged in user navigating main pages" do
    before do
      # Login as the primary user who is enrolled in challenge and groups
      login_as(primary_user)
    end

    describe "GET /reading" do
      it "returns http success" do
        get reading_path
        expect(response).to have_http_status(:success)
      end

      it "renders without errors when data exists" do
        get reading_path
        expect(response.body).to be_present
      end
    end

    describe "GET /stats" do
      it "returns http success" do
        get stats_path
        expect(response).to have_http_status(:success)
      end

      it "renders without errors when data exists" do
        get stats_path
        expect(response.body).to be_present
      end
    end

    describe "GET /stats/challenge" do
      it "returns http success" do
        get stats_challenge_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /stats/group" do
      it "returns http success" do
        get stats_group_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /stats/personal" do
      it "returns http success" do
        get stats_personal_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /groups" do
      it "redirects to user's group if they are already in one" do
        get groups_path
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(group_path(primary_group))
      end

      context "when user is not in a group" do
        # Test with a user who has no group membership
        before do
          login_as(inactive_user)
        end

        it "returns http success" do
          get groups_path
          expect(response).to have_http_status(:success)
        end

        it "renders without errors when groups exist" do
          get groups_path
          expect(response.body).to be_present
        end
      end
    end

    describe "GET /groups/:id" do
      it "returns http success for user's group" do
        get group_path(primary_group)
        expect(response).to have_http_status(:success)
      end

      it "renders group with messages" do
        get group_path(primary_group)
        expect(response.body).to be_present
      end
    end
  end

  describe "different users with different activity levels" do
    it "active user can access their stats" do
      login_as(active_user)
      get stats_path
      expect(response).to have_http_status(:success)
    end

    it "inactive user can access reading page" do
      login_as(inactive_user)
      get reading_path
      expect(response).to have_http_status(:success)
    end

    it "moderate user can access their group" do
      login_as(moderate_user)
      get group_path(primary_group)
      expect(response).to have_http_status(:success)
    end
  end

  describe "customizing test data per spec" do
    # Example of how to override or extend the shared context data
    let!(:custom_message) do
      create(:group_message,
        group: primary_group,
        user: primary_user,
        content: "This is a custom test message"
      )
    end

    it "works with additional custom data" do
      login_as(primary_user)
      get group_path(primary_group)
      expect(response).to have_http_status(:success)
      # The group now has the standard messages plus the custom one
    end
  end

  describe "using factory traits" do
    # Example of using the traits we added to factories
    let!(:encouraging_message) do
      create(:group_message, :encouraging, group: primary_group, user: primary_user)
    end

    let!(:question_message) do
      create(:group_message, :question, group: primary_group, user: active_user)
    end

    it "works with trait-created messages" do
      login_as(primary_user)
      get group_path(primary_group)
      expect(response).to have_http_status(:success)
    end
  end
end
