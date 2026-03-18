require 'rails_helper'

RSpec.describe "Challenge Invitation Link Label", type: :request do
  let(:challenge) { create(:challenge) }
  let(:user) { create(:user) }

  describe "GET /challenges/:id" do
    context "when user is not enrolled" do
      it "shows the invitation link label" do
        get challenge_path(challenge)
        expect(response.body).to include(I18n.t("challenges.get_invitation_link"))
      end
    end

    context "when user is enrolled" do
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      before { login_via_session(user) }

      it "does not show the invitation link label" do
        get challenge_path(challenge)
        expect(response.body).not_to include(I18n.t("challenges.get_invitation_link"))
      end
    end
  end
end
