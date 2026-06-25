require "rails_helper"

RSpec.describe "Manage::ApiAccess", type: :request do
  let(:owner)     { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  describe "GET /challenges/:challenge_id/manage/api_access" do
    context "as the challenge owner" do
      before { login_as owner }

      it "renders the page in the no-key state" do
        get challenge_manage_api_access_path(challenge)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t("manage.api_access.title"))
        expect(response.body).to include(I18n.t("manage.api_access.no_key_yet"))
      end

      it "shows the key once generated" do
        challenge.regenerate_api_key!
        get challenge_manage_api_access_path(challenge)
        expect(response.body).to include(challenge.api_key)
      end
    end

    context "as a user who cannot manage the challenge" do
      before { login_as create(:user) }

      it "redirects away" do
        get challenge_manage_api_access_path(challenge)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /challenges/:challenge_id/manage/api_access/regenerate" do
    before { login_as owner }

    it "generates a key when none exists" do
      expect {
        post regenerate_challenge_manage_api_access_path(challenge)
      }.to change { challenge.reload.api_key }.from(nil).to(be_present)

      expect(challenge.reload.api_key).to start_with("csmbc_")
      expect(response).to redirect_to(challenge_manage_api_access_path(challenge))
    end

    it "rotates an existing key" do
      challenge.regenerate_api_key!
      old_key = challenge.api_key

      post regenerate_challenge_manage_api_access_path(challenge)

      expect(challenge.reload.api_key).to be_present
      expect(challenge.api_key).not_to eq(old_key)
    end
  end
end
