require 'rails_helper'

# Helper method to parse JSON response
# Consider moving this to a spec helper if used across multiple files
def json_response
  JSON.parse(response.body)
end

# Placeholder for your authentication header generation
# Replace with your actual authentication mechanism
# e.g., if using Devise Token Auth: user.create_new_auth_token
def auth_headers_for(user)
  # This is a placeholder. Common pattern for token auth:
  # token = user.create_new_auth_token # or similar method depending on auth gem
  # return token if token.is_a?(Hash)
  # { 'Authorization' => "Bearer #{token}" } # or just the token hash itself
  { 'ACCEPT' => 'application/json' } # Basic header, actual auth needed
end

RSpec.describe "Api::V1::UserReadings", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let!(:challenge_utc) { FactoryBot.create(:challenge, timezone: "UTC") }
  let!(:challenge_est) { FactoryBot.create(:challenge, timezone: "Eastern Time (US & Canada)") }

  # Reading scheduled for today UTC
  let!(:reading_today_utc) { FactoryBot.create(:reading, challenge: challenge_utc, scheduled_date: Date.today) }
  # Reading scheduled for tomorrow UTC (so today EST if EST is UTC-5 and it's late UTC day)
  let!(:reading_tomorrow_utc_early_est) { FactoryBot.create(:reading, challenge: challenge_est, scheduled_date: Date.today) } # Scheduled for today EST
  let!(:reading_past_utc) { FactoryBot.create(:reading, challenge: challenge_utc, scheduled_date: Date.yesterday) }

  # --- Tests for nested routes: /api/v1/readings/:reading_id/user_reading --- 
  describe "POST /api/v1/readings/:reading_id/user_reading" do
    context "when authenticated" do
      before { sign_in user } # Assuming a Devise-like sign_in helper or use headers

      context "with valid conditions (correct date in challenge timezone)" do
        it "creates a new UserReading for the current user" do
          # Simulate it being today in UTC for a reading scheduled today in UTC
          allow(Time).to receive(:current).and_return(Time.now.utc)

          expect {
            post "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user)
          }.to change(UserReading, :count).by(1)
          
          expect(response).to have_http_status(:created)
          created_user_reading = UserReading.last
          expect(created_user_reading.user).to eq(user)
          expect(created_user_reading.reading).to eq(reading_today_utc)
          expect(created_user_reading.completed_on).to eq(Date.today) # As it's UTC
        end

        it "creates a UserReading if date matches in non-UTC timezone (e.g., EST)" do
          # Simulate a time that is 'today' in EST for a reading scheduled 'today' EST
          # Example: reading scheduled for 2023-10-27 EST.
          # If current actual time is 2023-10-27 02:00 UTC (which is 2023-10-26 22:00 EST), this should fail.
          # If current actual time is 2023-10-27 10:00 UTC (which is 2023-10-27 06:00 EST), this should pass.
          # Let's make reading_tomorrow_utc_early_est be scheduled for today in EST.
          # And set current time to be today in EST.
          est_time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
          allow(Time).to receive(:current).and_return(Time.now.in_time_zone(est_time_zone))

          expect {
            post "/api/v1/readings/#{reading_tomorrow_utc_early_est.id}/user_reading", headers: auth_headers_for(user)
          }.to change(UserReading, :count).by(1)
          
          expect(response).to have_http_status(:created)
          created_user_reading = UserReading.last
          expect(created_user_reading.completed_on).to eq(Date.today.in_time_zone(est_time_zone).to_date)
        end
      end

      context "when challenge timezone is not set" do
        let!(:challenge_no_tz) { FactoryBot.create(:challenge, timezone: nil) }
        let!(:reading_no_tz_challenge) { FactoryBot.create(:reading, challenge: challenge_no_tz, scheduled_date: Date.today) }
        it "returns unprocessable_entity" do
          post "/api/v1/readings/#{reading_no_tz_challenge.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to include("Challenge timezone not set for this reading.")
        end
      end

      context "when check-in date is incorrect for challenge timezone" do
        it "returns forbidden" do
          # reading_past_utc is scheduled for yesterday UTC. Today UTC should fail.
          allow(Time).to receive(:current).and_return(Time.now.utc)
          post "/api/v1/readings/#{reading_past_utc.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:forbidden)
          expect(json_response["errors"]).to include(/Check-ins are only allowed on the scheduled date/)
        end
      end

      context "when UserReading already exists" do
        before do 
          allow(Time).to receive(:current).and_return(Time.now.utc) # ensure date matches for setup
          FactoryBot.create(:user_reading, user: user, reading: reading_today_utc, completed_on: Date.today)
        end
        it "returns conflict" do
          post "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:conflict)
          expect(json_response["errors"]).to include("You have already marked this reading.")
        end
      end

      context "when reading is not found" do
        it "returns not_found" do
          post "/api/v1/readings/99999/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/readings/#{reading_today_utc.id}/user_reading"
        expect(response).to have_http_status(:unauthorized) # Or :forbidden depending on your auth setup
      end
    end
  end

  describe "DELETE /api/v1/readings/:reading_id/user_reading" do
    let!(:user_reading_to_delete) { FactoryBot.create(:user_reading, user: user, reading: reading_today_utc, completed_on: Date.today) }

    context "when authenticated" do
      before { sign_in user } # Assuming a Devise-like sign_in helper or use headers

      context "with valid conditions (correct date in challenge timezone)" do
        it "deletes the UserReading for the current user" do
          allow(Time).to receive(:current).and_return(Time.now.utc) # Match date for deletion
          expect {
            delete "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user)
          }.to change(UserReading, :count).by(-1)
          expect(response).to have_http_status(:no_content)
        end
      end

      context "when challenge timezone is not set for the reading's challenge" do
        let!(:challenge_no_tz) { FactoryBot.create(:challenge, timezone: nil) }
        let!(:reading_on_no_tz_challenge) { FactoryBot.create(:reading, challenge: challenge_no_tz, scheduled_date: Date.today) }
        let!(:ur_on_no_tz_challenge) { FactoryBot.create(:user_reading, user: user, reading: reading_on_no_tz_challenge, completed_on: Date.today) }
        
        it "returns unprocessable_entity" do
          delete "/api/v1/readings/#{reading_on_no_tz_challenge.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to include("Challenge timezone not set for this reading.")
        end
      end

      context "when uncheck date is incorrect for challenge timezone" do
        it "returns forbidden" do
          # user_reading_to_delete is for reading_today_utc. Trying to delete it on a 'different' day.
          allow(Time).to receive(:current).and_return(Time.now.utc + 2.days)
          delete "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:forbidden)
          expect(json_response["errors"]).to include(/Un-checking is only allowed on the scheduled date/)
        end
      end

      context "when UserReading to delete is not found (for this user/reading)" do
        it "returns not_found" do
          allow(Time).to receive(:current).and_return(Time.now.utc) # Match date for deletion attempt
          # Attempt to delete a check-in for a reading the user hasn't checked in, or another user's check-in
          other_reading = FactoryBot.create(:reading, challenge: challenge_utc, scheduled_date: Date.today)
          delete "/api/v1/readings/#{other_reading.id}/user_reading", headers: auth_headers_for(user)
          expect(response).to have_http_status(:not_found)
        end
      end

       context "when trying to delete another user's UserReading" do
        let!(:other_user_reading) { FactoryBot.create(:user_reading, user: other_user, reading: reading_today_utc, completed_on: Date.today) }
        it "returns not_found (as it's scoped to current_user and reading)" do
          allow(Time).to receive(:current).and_return(Time.now.utc)
          delete "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user) # user is signed in
          # This should try to delete current_user's UserReading for reading_today_utc.
          # If current_user doesn't have one, it will be a 404, even if other_user does.
          # The before_action set_user_reading_by_reading finds by (user: current_user, reading: @reading)
          expect(response).to have_http_status(:not_found) # Or :no_content if user_reading_to_delete was created above for `user`.
                                                         # Correcting the setup for clarity:
                                                         # Delete the one created for `user` in the outer let block if it exists
          user_reading_to_delete.destroy if defined?(user_reading_to_delete) && user_reading_to_delete.persisted?
          expect {
             delete "/api/v1/readings/#{reading_today_utc.id}/user_reading", headers: auth_headers_for(user)
          }.not_to change { UserReading.where(id: other_user_reading.id).count }
          expect(response).to have_http_status(:not_found) 
        end
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/readings/#{reading_today_utc.id}/user_reading"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # --- Tests for GET /api/v1/user_readings (index action) ---
  describe "GET /api/v1/user_readings" do
    context "when authenticated" do
      before { sign_in user } # Assuming a Devise-like sign_in helper or use headers
      let!(:ur1) { FactoryBot.create(:user_reading, user: user, reading: reading_today_utc, completed_on: Date.today) }
      let!(:ur2) { FactoryBot.create(:user_reading, user: user, reading: reading_past_utc, completed_on: Date.yesterday) }
      let!(:other_user_ur) { FactoryBot.create(:user_reading, user: other_user, reading: reading_today_utc, completed_on: Date.today) }

      it "returns a list of UserReadings for the current user" do
        get "/api/v1/user_readings", headers: auth_headers_for(user)
        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(2)
        expect(json_response.map{ |ur| ur["id"] }).to include(ur1.id, ur2.id)
        expect(json_response.map{ |ur| ur["id"] }).not_to include(other_user_ur.id)
      end

      it "includes reading data" do 
        get "/api/v1/user_readings", headers: auth_headers_for(user)
        expect(json_response.first["reading"]).to be_present
        expect(json_response.first["reading"]["id"]).to eq(reading_today_utc.id)
      end

      it "returns an empty list if the user has no check-ins" do
        ur1.destroy
        ur2.destroy
        get "/api/v1/user_readings", headers: auth_headers_for(user)
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/user_readings"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # --- Legacy tests from original file --- 
  # You might want to adapt or remove these if the legacy routes/actions are deprecated
  let!(:legacy_challenge) { FactoryBot.create(:challenge, timezone: "UTC") } # Added for legacy tests
  let!(:legacy_reading) { FactoryBot.create(:reading, challenge: legacy_challenge, scheduled_date: Date.today) } # Added

  describe "POST /api/v1/user_readings (Legacy)" do
    context "with valid parameters" do
      # Legacy endpoint expects completed_on, user_id, reading_id
      let(:valid_legacy_params) { { user_reading: { user_id: user.id, reading_id: legacy_reading.id, completed_on: Date.yesterday } } }

      it "creates a new UserReading record" do
        # Assuming create_legacy action is mapped and authenticate_user! is not run for it, or user is signed in.
        # For simplicity, let's assume it bypasses current_user logic or an admin is making the call.
        # Adjust if create_legacy also requires auth.
        expect {
          post "/api/v1/user_readings", params: valid_legacy_params #, headers: auth_headers_for(user) # if auth needed
        }.to change(UserReading, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["reading_id"]).to eq(legacy_reading.id)
        expect(json_response["completed_on"]).to eq(Date.yesterday.to_s)
      end

      context "when completed_on is not provided" do # As per create_legacy logic
        it "returns unprocessable_entity" do
            post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: legacy_reading.id } }
            expect(response).to have_http_status(:unprocessable_entity)
            expect(json_response["errors"]).to include("Completed on is required for this action")
        end
      end
    end

    context "when user_id is invalid (Legacy)" do
      it "returns not_found" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: 999, reading_id: legacy_reading.id, completed_on: Date.today } }
        expect(response).to have_http_status(:not_found)
        expect(json_response["errors"]).to include("User not found")
      end
    end

    context "when reading_id is invalid (Legacy)" do
      it "returns not_found" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: 999, completed_on: Date.today } }
        expect(response).to have_http_status(:not_found)
        expect(json_response["errors"]).to include("Reading not found")
      end
    end

    context "when record already exists (Legacy)" do
      before { FactoryBot.create(:user_reading, user: user, reading: legacy_reading, completed_on: Date.today) }
      it "returns unprocessable_entity" do
        post "/api/v1/user_readings", params: { user_reading: { user_id: user.id, reading_id: legacy_reading.id, completed_on: Date.today } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to include("User has already marked this reading")
      end
    end
  end

  describe "DELETE /api/v1/user_readings/:id (Legacy)" do
    let!(:user_reading_for_legacy_delete) { FactoryBot.create(:user_reading, user: user, reading: legacy_reading, completed_on: Date.today) }
    let!(:other_user_legacy_reading) { FactoryBot.create(:user_reading, user: other_user, reading: legacy_reading, completed_on: Date.today) }

    context "when authenticated as owner" do
      before { sign_in user }
      it "deletes the UserReading record" do
        expect {
          delete "/api/v1/user_readings/#{user_reading_for_legacy_delete.id}", headers: auth_headers_for(user)
        }.to change(UserReading, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it "does not delete another user_s UserReading record" do
        expect {
          delete "/api/v1/user_readings/#{other_user_legacy_reading.id}", headers: auth_headers_for(user)
        }.not_to change(UserReading, :count)
        expect(response).to have_http_status(:forbidden) # Due to ownership check in destroy_legacy
      end
    end

    context "when UserReading record does not exist (Legacy)" do
       before { sign_in user }
      it "returns not_found" do
        delete "/api/v1/user_readings/9999", headers: auth_headers_for(user)
        expect(response).to have_http_status(:not_found)
        # The message depends on set_user_reading_by_id: "UserReading record not found"
        expect(json_response["error"]).to eq("UserReading record not found")
      end
    end

    context "when not authenticated (Legacy)" do
      it "returns unauthorized" do # Or forbidden if authenticate_user! runs before ownership check
        delete "/api/v1/user_readings/#{user_reading_for_legacy_delete.id}"
        # This depends on whether authenticate_user! is called for destroy_legacy. 
        # If yes, it's :unauthorized. If no, and it hits current_user which is nil, it might error or deny.
        # The controller has before_action :authenticate_user! at the top.
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # Remove original json helper if the one at the top is preferred.
  # def json
  #   JSON.parse(response.body)
  # end
end
