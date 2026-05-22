require "rails_helper"

RSpec.describe "Groups country_code update", type: :request do
  let(:challenge) { create(:challenge, timezone: "UTC") }
  let(:creator) { create(:user, username: "creator_user") }
  let(:other_user) { create(:user, username: "other_user") }
  let(:group) { create(:group, challenge: challenge, creator: creator) }

  before do
    create(:user_challenge_enrollment, user: creator, challenge: challenge)
    create(:user_group_enrollment, user: creator, group: group)
    create(:user_challenge_enrollment, user: other_user, challenge: challenge)
  end

  describe "PATCH /groups/:id" do
    context "as the group creator" do
      before { login_via_session(creator) }

      it "allows setting country_code" do
        patch group_path(group), params: { group: { country_code: "DE" } }
        expect(group.reload.country_code).to eq("DE")
      end

      it "allows clearing country_code" do
        group.update!(country_code: "DE")
        patch group_path(group), params: { group: { country_code: "" } }
        expect(group.reload.country_code).to be_blank
      end

      it "rejects an invalid country code" do
        patch group_path(group), params: { group: { country_code: "ZZ" } }
        expect(group.reload.country_code).to be_nil
      end
    end

    context "as a non-creator" do
      before { login_via_session(other_user) }

      it "does not update country_code" do
        patch group_path(group), params: { group: { country_code: "DE" } }
        expect(group.reload.country_code).to be_nil
      end
    end
  end
end
