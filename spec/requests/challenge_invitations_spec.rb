require 'rails_helper'

RSpec.describe "Challenge Invitations", type: :request do
  let(:challenge) { FactoryBot.create(:challenge) }
  let(:user) { FactoryBot.create(:user) }

  describe "GET /challenges/:token/join" do
    context "with valid invitation token" do
      it "stores token in session and renders invitation landing page for non-logged-in users" do
        get challenge_invitation_path(challenge.invitation_token)

        expect(response).to have_http_status(:success)
        expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)
        expect(response.body).to include(challenge.name)
        expect(response.body).to include("Challenge Invitation")
      end

      context "when user is logged in" do
        before { login_via_session(user) }

        it "renders invitation landing page with accept button" do
          get challenge_invitation_path(challenge.invitation_token)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Accept Invitation &amp; Join")
        end
      end
    end

    context "with invalid invitation token" do
      it "redirects to root with error message" do
        get challenge_invitation_path("INVALID")

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Invalid invitation link")
      end
    end
  end

  describe "POST /challenges/:token/accept" do
    context "when user is logged in" do
      before { login_via_session(user) }

      it "enrolls user and redirects to reading page" do
        expect {
          post accept_challenge_invitation_path(challenge.invitation_token)
        }.to change(UserChallengeEnrollment, :count).by(1)

        expect(response).to redirect_to(reading_path)
        follow_redirect!
        expect(response.body).to include("Successfully joined #{challenge.name}")
      end
    end
  end
end
