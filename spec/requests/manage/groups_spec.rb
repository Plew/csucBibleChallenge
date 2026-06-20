require 'rails_helper'

RSpec.describe "Manage::Groups", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }
  let(:member) { create(:user) }
  let(:group) { create(:group, challenge: challenge, creator: owner) }

  before do
    create(:user_challenge_enrollment, user: member, challenge: challenge)
    login_as owner
  end

  describe "GET /challenges/:challenge_id/manage/groups" do
    it "returns success" do
      get challenge_manage_groups_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "lists groups with their members" do
      create(:user_group_enrollment, user: member, group: group)
      get challenge_manage_groups_path(challenge)
      expect(response.body).to include(group.name)
      expect(response.body).to include(member.username)
    end

    context "as an unauthorized user" do
      let(:outsider) { create(:user) }
      before { login_as outsider }

      it "redirects away" do
        get challenge_manage_groups_path(challenge)
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a challenge organizer (admin)" do
      let(:organizer) { create(:user) }
      before do
        create(:user_challenge_enrollment, :admin, user: organizer, challenge: challenge)
        login_as organizer
      end

      it "returns success" do
        get challenge_manage_groups_path(challenge)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/groups/:id" do
    it "renames the group" do
      patch challenge_manage_group_path(challenge, group), params: { group: { name: "New Name" } }
      expect(group.reload.name).to eq("New Name")
      expect(response).to redirect_to(challenge_manage_groups_path(challenge))
    end

    it "rejects a duplicate name within the challenge" do
      other = create(:group, challenge: challenge, creator: owner, name: "Taken")
      patch challenge_manage_group_path(challenge, group), params: { group: { name: "Taken" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "as an unauthorized user" do
      let(:outsider) { create(:user) }
      before { login_as outsider }

      it "redirects away" do
        patch challenge_manage_group_path(challenge, group), params: { group: { name: "Hacked" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/groups/:id" do
    it "destroys the group" do
      group
      expect {
        delete challenge_manage_group_path(challenge, group)
      }.to change(Group, :count).by(-1)
      expect(response).to redirect_to(challenge_manage_groups_path(challenge))
    end

    it "leaves former members enrolled in the challenge" do
      create(:user_group_enrollment, user: member, group: group)
      delete challenge_manage_group_path(challenge, group)
      expect(member.user_challenge_enrollments.where(challenge: challenge)).to exist
    end

    context "as an unauthorized user" do
      let(:outsider) { create(:user) }
      before { login_as outsider }

      it "redirects away" do
        delete challenge_manage_group_path(challenge, group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/groups/:id/remove_member" do
    before { create(:user_group_enrollment, user: member, group: group) }

    it "removes the member from the group" do
      expect {
        delete remove_member_challenge_manage_group_path(challenge, group), params: { user_id: member.id }
      }.to change(UserGroupEnrollment, :count).by(-1)
      expect(response).to redirect_to(challenge_manage_groups_path(challenge))
    end

    it "keeps the member enrolled in the challenge" do
      delete remove_member_challenge_manage_group_path(challenge, group), params: { user_id: member.id }
      expect(member.user_challenge_enrollments.where(challenge: challenge)).to exist
    end

    context "as an unauthorized user" do
      let(:outsider) { create(:user) }
      before { login_as outsider }

      it "redirects away" do
        delete remove_member_challenge_manage_group_path(challenge, group), params: { user_id: member.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/groups/:id/move_member" do
    let(:target_group) { create(:group, challenge: challenge, creator: owner) }

    before { create(:user_group_enrollment, user: member, group: group) }

    it "moves the member to the target group" do
      patch move_member_challenge_manage_group_path(challenge, group),
            params: { user_id: member.id, target_group_id: target_group.id }
      expect(member.groups.where(challenge: challenge)).to contain_exactly(target_group)
      expect(response).to redirect_to(challenge_manage_groups_path(challenge))
    end

    it "leaves the member in exactly one group" do
      patch move_member_challenge_manage_group_path(challenge, group),
            params: { user_id: member.id, target_group_id: target_group.id }
      expect(member.user_group_enrollments.joins(:group).where(groups: { challenge_id: challenge.id }).count).to eq(1)
    end

    context "as an unauthorized user" do
      let(:outsider) { create(:user) }
      before { login_as outsider }

      it "redirects away" do
        patch move_member_challenge_manage_group_path(challenge, group),
              params: { user_id: member.id, target_group_id: target_group.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
