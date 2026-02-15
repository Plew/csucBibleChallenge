require 'rails_helper'

RSpec.describe "Manage::Users", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }
  let(:enrolled_user) { create(:user, username: "testparticipant") }

  before do
    create(:user_challenge_enrollment, user: enrolled_user, challenge: challenge)
    login_as owner
  end

  describe "GET /challenges/:challenge_id/manage/users" do
    it "returns success" do
      get challenge_manage_users_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays enrolled users" do
      get challenge_manage_users_path(challenge)
      expect(response.body).to include("testparticipant")
    end

    it "filters users by search" do
      get challenge_manage_users_path(challenge, search: "testparticipant")
      expect(response.body).to include("testparticipant")
    end
  end

  describe "GET /challenges/:challenge_id/manage/users/:id" do
    it "returns success" do
      get challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/users/:id/remove" do
    it "removes the user from the challenge" do
      expect {
        delete remove_challenge_manage_user_path(challenge, enrolled_user)
      }.to change(UserChallengeEnrollment, :count).by(-1)
    end

    it "redirects to users index" do
      delete remove_challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to redirect_to(challenge_manage_users_path(challenge))
    end
  end

  describe "GET /challenges/:challenge_id/manage/users/:id/change_password" do
    it "returns success" do
      get change_password_challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/users/:id/update_password" do
    it "updates the password" do
      patch update_password_challenge_manage_user_path(challenge, enrolled_user), params: { new_password: "newpass123" }
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      expect(enrolled_user.reload.authenticate("newpass123")).to be_truthy
    end

    it "rejects blank password" do
      patch update_password_challenge_manage_user_path(challenge, enrolled_user), params: { new_password: "" }
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
    end

    it "rejects short password" do
      patch update_password_challenge_manage_user_path(challenge, enrolled_user), params: { new_password: "abc" }
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { create(:user) }
    before { login_as other_user }

    it "denies access to user list" do
      get challenge_manage_users_path(challenge)
      expect(response).to redirect_to(root_path)
    end

    it "denies removing users" do
      expect {
        delete remove_challenge_manage_user_path(challenge, enrolled_user)
      }.not_to change(UserChallengeEnrollment, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
