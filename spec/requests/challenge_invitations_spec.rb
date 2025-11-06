require 'rails_helper'

RSpec.describe "Challenge Invitations", type: :request do
  let(:challenge) { FactoryBot.create(:challenge) }
  let(:user) { FactoryBot.create(:user) }

  describe "GET /challenges/:token/join" do
    context "with valid invitation token" do
      it "stores token in session and redirects to challenge show page for non-logged-in users" do
        get challenge_invitation_path(challenge.invitation_token)

        expect(response).to redirect_to(challenge_path(challenge))
        expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)

        # Follow redirect and verify challenge name appears
        follow_redirect!
        expect(response.body).to include(challenge.name)
      end

      context "when user is logged in" do
        before { log_in_user(user) }

        it "auto-enrolls user and redirects to reading page" do
          expect {
            get challenge_invitation_path(challenge.invitation_token)
          }.to change(UserChallengeEnrollment, :count).by(1)

          expect(response).to redirect_to(reading_path)
          follow_redirect!
          expect(response.body).to include("Successfully joined #{challenge.name}")
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

  private

  def log_in_user(user)
    post user_session_path, params: {
      session: { email: user.email, password: user.password }
    }
  end
end
