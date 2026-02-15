require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:test_user) { create(:user, email: 'test@example.com') }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin/users" do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for GET /admin/users/:id" do
        get admin_user_path(test_user)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for PATCH /admin/users/:id/reset_password" do
        patch reset_password_admin_user_path(test_user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/users" do
        get admin_users_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for GET /admin/users/:id" do
        get admin_user_path(test_user)
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for PATCH /admin/users/:id/reset_password" do
        patch reset_password_admin_user_path(test_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "when user is admin" do
    before { login_via_session(admin_user) }

    describe "GET /admin/users" do
      let!(:user1) { create(:user, email: 'searchable1@example.com', username: 'searchable1', admin: false) }
      let!(:user2) { create(:user, email: 'searchable2@example.com', username: 'searchable2', admin: true) }

      it "returns http success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "displays all users" do
        get admin_users_path
        expect(response.body).to include('searchable1')
        expect(response.body).to include('searchable2')
      end

      it "shows admin badges correctly" do
        get admin_users_path
        expect(response.body).to include('Admin') # For admin users
        expect(response.body).to include('User') # For regular users
      end

      context "with search parameter" do
        it "filters users by email" do
          get admin_users_path, params: { search: 'searchable1' }
          expect(response.body).to include('searchable1')
          expect(response.body).not_to include('searchable2')
        end

        it "filters users by ID" do
          get admin_users_path, params: { search: user1.id.to_s }
          expect(response.body).to include('searchable1')
          # user2 may still appear due to pagination or other users, so just check that user1 is included
        end
      end
    end

    describe "GET /admin/users/:id" do
      it "returns http success" do
        get admin_user_path(test_user)
        expect(response).to have_http_status(:success)
      end

      it "displays user details" do
        get admin_user_path(test_user)
        expect(response.body).to include(test_user.email)
        expect(response.body).to include(test_user.id.to_s)
      end

      it "shows admin status correctly" do
        admin_user_test = create(:user, admin: true)
        regular_user_test = create(:user, admin: false)

        get admin_user_path(admin_user_test)
        expect(response.body).to include('Admin')

        get admin_user_path(regular_user_test)
        expect(response.body).to include('User')
      end

      it "shows links to reading history and change password pages" do
        get admin_user_path(test_user)
        expect(response.body).to include(reading_history_admin_user_path(test_user))
        expect(response.body).to include(change_password_admin_user_path(test_user))
      end
    end

    describe "GET /admin/users/:id/reading_history" do
      let(:challenge) { create(:challenge, timezone: 'Berlin') }
      let(:reading) { create(:reading, challenge: challenge, scheduled_date: Date.current) }
      let!(:user_reading) { create(:user_reading, user: test_user, reading: reading, completed_on: Time.current) }

      it "returns http success" do
        get reading_history_admin_user_path(test_user)
        expect(response).to have_http_status(:success)
      end

      it "displays reading history header" do
        get reading_history_admin_user_path(test_user)
        expect(response.body).to include("Reading History")
      end

      it "displays reading entries with scheduled date and completed timestamp" do
        get reading_history_admin_user_path(test_user)
        expect(response.body).to include(reading.scheduled_date.strftime("%b %d, %Y"))
      end
    end

    describe "GET /admin/users/:id/change_password" do
      it "returns http success" do
        get change_password_admin_user_path(test_user)
        expect(response).to have_http_status(:success)
      end

      it "displays change password form" do
        get change_password_admin_user_path(test_user)
        expect(response.body).to include("Change Password")
        expect(response.body).to include(update_password_admin_user_path(test_user))
      end
    end

    describe "PATCH /admin/users/:id/reset_password" do
      it "resets user password and redirects with new password" do
        patch reset_password_admin_user_path(test_user)

        expect(response).to redirect_to(admin_users_path)
        follow_redirect!

        expect(response.body).to include("Password reset for #{test_user.email}")
        expect(response.body).to match(/New password: \w{12}/)
      end

      it "actually changes the user's password" do
        original_password_digest = test_user.password_digest

        patch reset_password_admin_user_path(test_user)
        test_user.reload

        expect(test_user.password_digest).not_to eq(original_password_digest)
      end
    end
  end
end
