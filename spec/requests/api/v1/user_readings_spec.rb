require 'rails_helper'

RSpec.describe "Api::V1::UserReadings", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:challenge) { FactoryBot.create(:challenge) }
  let!(:reading) { FactoryBot.create(:reading, challenge: challenge) }

  describe "POST /api/v1/user_readings" do
    context "with valid parameters" do
      let(:valid_params) { { user_reading: { user_id: user.id, reading_id: reading.id, completed_on: Date.yesterday } } }

      it "creates a new UserReading record" do
        expect {
          post "/api/v1/user_readings", params: valid_params
        }.to change(UserReading, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json["user_id"]).to eq(user.id)
        expect(json["reading_id"]).to eq(reading.id)
        expect(json["completed_on"]).to eq(Date.yesterday.to_s)
      end

      it "defaults completed_on to today if not provided" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: reading.id } }
        expect(response).to have_http_status(:created)
        expect(json["completed_on"]).to eq(Date.today.to_s)
      end
    end

    context "when user_id is invalid" do
      it "returns not_found" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: 999, reading_id: reading.id } }
        expect(response).to have_http_status(:not_found)
        expect(json["errors"]).to include("User not found")
      end
    end

    context "when reading_id is invalid" do
      it "returns not_found" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: 999 } }
        expect(response).to have_http_status(:not_found)
        expect(json["errors"]).to include("Reading not found")
      end
    end

    context "when record already exists (user has already marked this reading)" do
      before { FactoryBot.create(:user_reading, user: user, reading: reading) }
      it "returns unprocessable_entity" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: reading.id } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["errors"]).to include("User has already marked this reading")
      end
    end
  end

  describe "DELETE /api/v1/user_readings/:id" do
    let!(:user_reading) { FactoryBot.create(:user_reading, user: user, reading: reading) }

    it "deletes the UserReading record" do
      expect {
        delete "/api/v1/user_readings/#{user_reading.id}"
      }.to change(UserReading, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    context "when UserReading record does not exist" do
      it "returns not_found" do
        delete "/api/v1/user_readings/9999"
        expect(response).to have_http_status(:not_found)
        expect(json["error"]).to eq("UserReading record not found")
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
