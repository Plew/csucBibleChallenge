require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /index" do
    pending "add some examples (or delete) #{__FILE__}"
  end

  describe "POST /api/v1/users" do
    context "with valid parameters" do
      let(:valid_params) do
        { user: { username: "testuser", email: "test@example.com", password: "password123", password_confirmation: "password123" } }
      end

      it "creates a new User" do
        expect {
          post "/api/v1/users", params: valid_params
        }.to change(User, :count).by(1)
      end

      it "returns a created status" do
        post "/api/v1/users", params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "returns the created user as JSON (without password_digest)" do
        post "/api/v1/users", params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response["username"]).to eq("testuser")
        expect(json_response["email"]).to eq("test@example.com")
        expect(json_response).not_to have_key("password_digest")
      end
    end

    context "with invalid parameters" do
      it "does not create a User if username is missing" do
        invalid_params = { user: { email: "test@example.com", password: "password123", password_confirmation: "password123" } }
        expect {
          post "/api/v1/users", params: invalid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Username can't be blank")
      end

      it "does not create a User if email is invalid" do
        invalid_params = { user: { username: "testuser", email: "invalid_email", password: "password123", password_confirmation: "password123" } }
        expect {
          post "/api/v1/users", params: invalid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Email is invalid")
      end

      it "does not create a User if password is too short" do
        invalid_params = { user: { username: "testuser", email: "test@example.com", password: "123", password_confirmation: "123" } }
        expect {
          post "/api/v1/users", params: invalid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Password is too short (minimum is 6 characters)")
      end

      it "does not create a User if password confirmation doesn't match" do
        invalid_params = { user: { username: "testuser", email: "test@example.com", password: "password123", password_confirmation: "wrongpassword" } }
        expect {
          post "/api/v1/users", params: invalid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Password confirmation doesn't match Password")
      end

      it "does not create a user if email is already taken" do
        FactoryBot.create(:user, email: "taken@example.com")
        invalid_params = { user: { username: "newuser", email: "taken@example.com", password: "password123", password_confirmation: "password123" } }
        expect {
          post "/api/v1/users", params: invalid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Email has already been taken")
      end
    end
  end
end
