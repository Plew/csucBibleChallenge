require 'rails_helper'

RSpec.describe CampusPairingsController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, name: "New Testament 2026") }

  before do
    user.user_challenge_enrollments.create(challenge: challenge)
  end

  describe "GET #new" do
    context "when not logged in" do
      it "redirects to login and saves return_to path" do
        get :new, params: {
          campus_name: "Christian Students at UC",
          hub_url: "https://uc-campushub.org",
          secret: "secret123",
          nonce: "nonceABC",
          callback_url: "https://uc-campushub.org/api/sso/callback"
        }
        expect(response).to redirect_to(new_user_session_path)
        expect(session[:user_return_to]).to include("/campus/pair")
      end
    end

    context "when logged in" do
      before { session[:user_id] = user.id }

      it "renders the pairing form with parameters" do
        get :new, params: {
          campus_name: "Christian Students at UC",
          hub_url: "https://uc-campushub.org",
          secret: "secret123",
          nonce: "nonceABC",
          callback_url: "https://uc-campushub.org/api/sso/callback"
        }
        expect(response).to be_successful
        expect(assigns(:campus_name)).to eq("Christian Students at UC")
        expect(assigns(:hub_url)).to eq("https://uc-campushub.org")
        expect(assigns(:challenges)).to include(challenge)
      end
    end
  end

  describe "POST #create" do
    before { session[:user_id] = user.id }

    it "creates a CampusConnection and redirects to callback_url with parameters" do
      expect {
        post :create, params: {
          campus_name: "Christian Students at UC",
          hub_url: "https://uc-campushub.org/",
          secret: "my_campus_sso_secret_789",
          nonce: "unique_nonce_123",
          challenge_id: challenge.id,
          callback_url: "https://uc-campushub.org/api/sso/callback"
        }
      }.to change(CampusConnection, :count).by(1)

      connection = CampusConnection.last
      expect(connection.campus_name).to eq("Christian Students at UC")
      expect(connection.hub_url).to eq("https://uc-campushub.org")
      expect(connection.sso_secret).to eq("my_campus_sso_secret_789")
      expect(connection.challenge).to eq(challenge)
      expect(connection.user).to eq(user)

      expect(response).to be_redirect
      expect(response.location).to include("status=success")
      expect(response.location).to include("challenge_id=#{challenge.id}")
      expect(response.location).to include("nonce=unique_nonce_123")
    end

    it "updates an existing CampusConnection if hub_url is already paired" do
      existing = CampusConnection.create!(
        user: user,
        campus_name: "Old Name",
        hub_url: "https://uc-campushub.org",
        sso_secret: "old_secret",
        challenge: nil
      )

      expect {
        post :create, params: {
          campus_name: "Updated Campus Name",
          hub_url: "https://uc-campushub.org",
          secret: "new_secret_456",
          nonce: "nonceXYZ",
          challenge_id: challenge.id,
          callback_url: "https://uc-campushub.org/api/sso/callback"
        }
      }.not_to change(CampusConnection, :count)

      existing.reload
      expect(existing.campus_name).to eq("Updated Campus Name")
      expect(existing.sso_secret).to eq("new_secret_456")
      expect(existing.challenge).to eq(challenge)
    end
  end
end
