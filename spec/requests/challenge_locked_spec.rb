require 'rails_helper'

RSpec.describe "Challenge Locking", type: :request do
  let(:creator) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe "enrollment blocked when locked" do
    let(:locked_challenge) { create(:challenge, locked: true) }

    before { login_via_session(user) }

    it "rejects enrollment via POST" do
      post challenge_enrollments_path(challenge_id: locked_challenge.id)
      expect(response).to redirect_to(challenge_path(locked_challenge))
      follow_redirect!
      expect(response.body).to include(I18n.t("challenges.signups_closed"))
    end
  end

  describe "invitation shows locked message" do
    let(:locked_challenge) { create(:challenge, locked: true) }

    it "redirects with locked message for logged-in user" do
      login_via_session(user)
      get challenge_invitation_path(locked_challenge.invitation_token)
      expect(response).to redirect_to(challenge_path(locked_challenge))
      expect(flash[:alert]).to eq(I18n.t("challenges.signups_closed"))
    end

    it "redirects with locked message for logged-out user" do
      get challenge_invitation_path(locked_challenge.invitation_token)
      expect(response).to redirect_to(challenge_path(locked_challenge))
      expect(flash[:alert]).to eq(I18n.t("challenges.signups_closed"))
    end
  end

  describe "challenge show page" do
    let(:locked_challenge) { create(:challenge, locked: true) }

    it "shows signups closed badge for non-enrolled user" do
      get challenge_path(locked_challenge)
      expect(response.body).to include(I18n.t("challenges.signups_closed"))
    end

    it "hides join button when locked" do
      get challenge_path(locked_challenge)
      expect(response.body).not_to include(I18n.t("challenges.join_challenge"))
    end
  end

  describe "manage settings update" do
    let(:challenge) { create(:challenge, creator: creator) }

    before { login_via_session(creator) }

    it "can lock a challenge" do
      patch challenge_manage_settings_path(challenge), params: { challenge: { locked: true } }
      expect(challenge.reload.locked?).to be(true)
    end

    it "can unlock a challenge" do
      challenge.update!(locked: true)
      patch challenge_manage_settings_path(challenge), params: { challenge: { locked: false } }
      expect(challenge.reload.locked?).to be(false)
    end
  end
end
