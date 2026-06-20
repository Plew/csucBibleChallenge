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

    context "with activity filtering" do
      let(:active_user) { create(:user, username: "xactiveuser") }
      let(:inactive_user) { create(:user, username: "xinactiveuser") }

      before do
        create(:user_challenge_enrollment, user: active_user, challenge: challenge)
        create(:user_challenge_enrollment, user: inactive_user, challenge: challenge)

        reading = create(:reading, challenge: challenge, scheduled_date: 2.days.ago)
        create(:user_reading, user: active_user, reading: reading, completed_on: 2.days.ago)
      end

      it "filters users with no activity in last 7 days" do
        get challenge_manage_users_path(challenge, inactive_days: 7)
        expect(response.body).to include("xinactiveuser")
        expect(response.body).not_to include("xactiveuser")
      end

      it "filters users with no activity in last 10 days" do
        get challenge_manage_users_path(challenge, inactive_days: 10)
        expect(response.body).to include("xinactiveuser")
        expect(response.body).not_to include("xactiveuser")
      end
    end
  end

  describe "GET /challenges/:challenge_id/manage/users/:id" do
    it "returns success" do
      get challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to have_http_status(:success)
    end

    it "shows group info when user is in a group" do
      group = create(:group, challenge: challenge, creator: owner)
      create(:user_group_enrollment, user: enrolled_user, group: group)
      get challenge_manage_user_path(challenge, enrolled_user)
      expect(response.body).to include(group.name)
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

  describe "DELETE /challenges/:challenge_id/manage/users/:id/remove_from_group" do
    let(:group) { create(:group, challenge: challenge, creator: owner) }

    before do
      create(:user_group_enrollment, user: enrolled_user, group: group)
    end

    it "removes the user from their group in this challenge" do
      expect {
        delete remove_from_group_challenge_manage_user_path(challenge, enrolled_user)
      }.to change(UserGroupEnrollment, :count).by(-1)
    end

    it "does NOT remove the user from the challenge" do
      expect {
        delete remove_from_group_challenge_manage_user_path(challenge, enrolled_user)
      }.not_to change(UserChallengeEnrollment, :count)
    end

    it "redirects to user show page" do
      delete remove_from_group_challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
    end

    it "shows error when user is not in a group" do
      UserGroupEnrollment.where(user: enrolled_user).delete_all
      delete remove_from_group_challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /challenges/:challenge_id/manage/users/bulk_remove_from_groups" do
    let(:group) { create(:group, challenge: challenge, creator: owner) }
    let(:user2) { create(:user) }

    before do
      create(:user_challenge_enrollment, user: user2, challenge: challenge)
      create(:user_group_enrollment, user: enrolled_user, group: group)
      create(:user_group_enrollment, user: user2, group: group)
    end

    it "removes selected users from their groups" do
      expect {
        post bulk_remove_from_groups_challenge_manage_users_path(challenge), params: { user_ids: [ enrolled_user.id, user2.id ] }
      }.to change(UserGroupEnrollment, :count).by(-2)
    end

    it "redirects to users index" do
      post bulk_remove_from_groups_challenge_manage_users_path(challenge), params: { user_ids: [ enrolled_user.id ] }
      expect(response).to redirect_to(challenge_manage_users_path(challenge))
    end

    it "shows error when no users selected" do
      post bulk_remove_from_groups_challenge_manage_users_path(challenge)
      expect(response).to redirect_to(challenge_manage_users_path(challenge))
      expect(flash[:alert]).to be_present
    end

    it "only removes from groups within this challenge" do
      other_challenge = create(:challenge, creator: owner)
      other_group = create(:group, challenge: other_challenge, creator: owner)
      create(:user_challenge_enrollment, user: enrolled_user, challenge: other_challenge)
      other_enrollment = create(:user_group_enrollment, user: enrolled_user, group: other_group)

      post bulk_remove_from_groups_challenge_manage_users_path(challenge), params: { user_ids: [ enrolled_user.id ] }
      expect(UserGroupEnrollment.exists?(other_enrollment.id)).to be true
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

  describe "PATCH /challenges/:challenge_id/manage/users/:id/promote" do
    it "promotes a user to organizer" do
      patch promote_challenge_manage_user_path(challenge, enrolled_user)
      expect(enrolled_user.user_challenge_enrollments.find_by(challenge: challenge).role).to eq("organizer")
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      expect(flash[:notice]).to include(enrolled_user.username)
    end

    it "prevents promoting the creator" do
      create(:user_challenge_enrollment, user: owner, challenge: challenge)
      patch promote_challenge_manage_user_path(challenge, owner)
      expect(response).to redirect_to(challenge_manage_user_path(challenge, owner))
      expect(flash[:alert]).to be_present
    end

    context "when logged in as a site admin" do
      let(:site_admin) { create(:user, admin: true) }

      before { login_as site_admin }

      it "allows promote action" do
        patch promote_challenge_manage_user_path(challenge, enrolled_user)
        expect(enrolled_user.user_challenge_enrollments.find_by(challenge: challenge).role).to eq("organizer")
        expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      end
    end

    context "when logged in as a challenge organizer (not creator)" do
      let(:organizer) { create(:user) }

      before do
        create(:user_challenge_enrollment, :organizer, user: organizer, challenge: challenge)
        login_as organizer
      end

      it "denies promote action" do
        patch promote_challenge_manage_user_path(challenge, enrolled_user)
        expect(response).to redirect_to(challenge_manage_dashboard_path(challenge))
      end
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/users/:id/demote" do
    before do
      enrolled_user.user_challenge_enrollments.find_by(challenge: challenge).update!(role: "organizer")
    end

    it "demotes a user from organizer" do
      patch demote_challenge_manage_user_path(challenge, enrolled_user)
      expect(enrolled_user.user_challenge_enrollments.find_by(challenge: challenge).role).to eq("member")
      expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      expect(flash[:notice]).to include(enrolled_user.username)
    end

    context "when logged in as a site admin" do
      let(:site_admin) { create(:user, admin: true) }

      before { login_as site_admin }

      it "allows demote action" do
        patch demote_challenge_manage_user_path(challenge, enrolled_user)
        expect(enrolled_user.user_challenge_enrollments.find_by(challenge: challenge).role).to eq("member")
        expect(response).to redirect_to(challenge_manage_user_path(challenge, enrolled_user))
      end
    end

    context "when logged in as a challenge organizer (not creator)" do
      let(:organizer) { create(:user) }

      before do
        create(:user_challenge_enrollment, :organizer, user: organizer, challenge: challenge)
        login_as organizer
      end

      it "denies demote action" do
        patch demote_challenge_manage_user_path(challenge, enrolled_user)
        expect(response).to redirect_to(challenge_manage_dashboard_path(challenge))
      end
    end
  end

  context "when logged in as a challenge organizer" do
    let(:organizer_user) { create(:user) }

    before do
      create(:user_challenge_enrollment, :organizer, user: organizer_user, challenge: challenge)
      login_as organizer_user
    end

    it "allows access to user list" do
      get challenge_manage_users_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "allows viewing a user" do
      get challenge_manage_user_path(challenge, enrolled_user)
      expect(response).to have_http_status(:success)
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
