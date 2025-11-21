require 'rails_helper'

RSpec.describe "Admin::Badges", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:badge) { create(:badge) }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin/badges" do
        get admin_badges_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for GET /admin/badges/new" do
        get new_admin_badge_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for POST /admin/badges" do
        post admin_badges_path, params: { badge: { name: 'Test Badge', description: 'Test', icon: '🏆' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/badges" do
        get admin_badges_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for GET /admin/badges/new" do
        get new_admin_badge_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for POST /admin/badges" do
        post admin_badges_path, params: { badge: { name: 'Test Badge', description: 'Test', icon: '🏆' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/badges" do
    before { login_via_session(admin_user) }

    let!(:badge1) { create(:badge, name: "Perfect Week", icon: "🏆") }
    let!(:badge2) { create(:badge, name: "Early Bird", icon: "🌅") }

    it "returns http success" do
      get admin_badges_path
      expect(response).to have_http_status(:success)
    end

    it "displays all badges" do
      get admin_badges_path
      expect(response.body).to include("Perfect Week")
      expect(response.body).to include("Early Bird")
    end
  end

  describe "GET /admin/badges/:id" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get admin_badge_path(badge)
      expect(response).to have_http_status(:success)
    end

    it "displays badge details" do
      get admin_badge_path(badge)
      expect(response.body).to include(badge.name)
      expect(response.body).to include(badge.description)
    end
  end

  describe "GET /admin/badges/new" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get new_admin_badge_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/badges/:id/edit" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get edit_admin_badge_path(badge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/badges" do
    before { login_via_session(admin_user) }

    context "with valid parameters" do
      let(:valid_attributes) do
        { name: "Perfect Week", description: "Completed all readings for a week", icon: "🏆" }
      end

      it "creates a new badge" do
        expect {
          post admin_badges_path, params: { badge: valid_attributes }
        }.to change(Badge, :count).by(1)
      end

      it "redirects to the badges index" do
        post admin_badges_path, params: { badge: valid_attributes }
        expect(response).to redirect_to(admin_badges_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { name: "", description: "", icon: "" }
      end

      it "does not create a new badge" do
        expect {
          post admin_badges_path, params: { badge: invalid_attributes }
        }.not_to change(Badge, :count)
      end

      it "renders the new template" do
        post admin_badges_path, params: { badge: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /admin/badges/:id" do
    before { login_via_session(admin_user) }

    context "with valid parameters" do
      let(:new_attributes) do
        { name: "Updated Badge Name", description: "Updated description" }
      end

      it "updates the badge" do
        patch admin_badge_path(badge), params: { badge: new_attributes }
        badge.reload
        expect(badge.name).to eq("Updated Badge Name")
        expect(badge.description).to eq("Updated description")
      end

      it "redirects to the badges index" do
        patch admin_badge_path(badge), params: { badge: new_attributes }
        expect(response).to redirect_to(admin_badges_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { name: "", description: "" }
      end

      it "does not update the badge" do
        original_name = badge.name
        patch admin_badge_path(badge), params: { badge: invalid_attributes }
        badge.reload
        expect(badge.name).to eq(original_name)
      end

      it "renders the edit template" do
        patch admin_badge_path(badge), params: { badge: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/badges/:id" do
    before { login_via_session(admin_user) }

    it "destroys the badge" do
      badge_to_delete = create(:badge)
      expect {
        delete admin_badge_path(badge_to_delete)
      }.to change(Badge, :count).by(-1)
    end

    it "redirects to badges index" do
      delete admin_badge_path(badge)
      expect(response).to redirect_to(admin_badges_path)
    end
  end
end
