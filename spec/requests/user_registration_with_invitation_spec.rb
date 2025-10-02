require 'rails_helper'

RSpec.describe "User Registration with Challenge Invitation", type: :request do
  let(:challenge) { FactoryBot.create(:challenge) }

  describe "complete invitation flow" do
    it "handles full user journey: invitation link → signup → auto-join → reading page" do
      # Step 1: User clicks invitation link (redirects to challenge show page)
      get challenge_invitation_path(challenge.invitation_token)
      expect(response).to redirect_to(challenge_path(challenge))
      expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)

      # Step 2: User goes to signup page
      get new_user_registration_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Create your account.")

      # Step 3: User submits signup form
      user_params = {
        username: "newuser",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }

      expect {
        post users_path, params: { user: user_params }
      }.to change(User, :count).by(1)
        .and change(UserChallengeEnrollment, :count).by(1)

      # Step 4: User is redirected to reading page with success message
      expect(response).to redirect_to(reading_path)
      follow_redirect!
      expect(response.body).to include("automatically enrolled in #{challenge.name}")

      # Step 5: Verify user is enrolled and session is cleaned up
      new_user = User.find_by(email: "newuser@example.com")
      expect(new_user.challenges).to include(challenge)
      expect(session[:challenge_invitation_token]).to be_nil
    end

    it "handles signup without invitation token (normal flow)" do
      user_params = {
        username: "normaluser",
        email: "normal@example.com", 
        password: "password123",
        password_confirmation: "password123"
      }

      expect {
        post users_path, params: { user: user_params }
      }.to change(User, :count).by(1)
        .and change(UserChallengeEnrollment, :count).by(0)

      expect(response).to redirect_to(root_path)
    end

    it "handles signup with invalid invitation token" do
      # Set invalid token in session
      post user_session_path, params: { session: { email: "fake", password: "fake" } }
      session[:challenge_invitation_token] = "INVALID"

      user_params = {
        username: "testuser",
        email: "test@example.com",
        password: "password123", 
        password_confirmation: "password123"
      }

      expect {
        post users_path, params: { user: user_params }
      }.to change(User, :count).by(1)
        .and change(UserChallengeEnrollment, :count).by(0)

      expect(response).to redirect_to(root_path)
      expect(session[:challenge_invitation_token]).to be_nil
    end

    it "handles enrollment failure when challenge not found" do
      # Visit invitation page 
      get challenge_invitation_path(challenge.invitation_token)
      expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)

      # Delete the challenge to simulate invalid token scenario
      challenge.destroy

      user_params = {
        username: "testuser",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }

      expect {
        post users_path, params: { user: user_params }
      }.to change(User, :count).by(1)
        .and change(UserChallengeEnrollment, :count).by(0)
      
      # Token should be cleared even if enrollment fails
      expect(session[:challenge_invitation_token]).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "preserves invitation token on signup validation errors" do
      # Visit invitation page first
      get challenge_invitation_path(challenge.invitation_token)
      expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)

      # Submit invalid signup form
      invalid_user_params = {
        username: "",
        email: "invalid-email",
        password: "123",
        password_confirmation: "456"
      }

      expect {
        post users_path, params: { user: invalid_user_params }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Create your account.")
      # Session token should still be present for retry
      expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)
    end
  end
end