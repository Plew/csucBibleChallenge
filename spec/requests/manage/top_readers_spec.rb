require 'rails_helper'

RSpec.describe "Manage::TopReaders", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner, start_date: Date.current - 20, end_date: Date.current + 10) }

  let!(:readings) do
    dates = (Date.current - 19..Date.current - 10).to_a
    create_list(:reading, 10, challenge: challenge) { |reading, i| reading.scheduled_date = dates[i]; reading.save! }
  end

  describe "GET /challenges/:challenge_id/manage/top_readers" do
    context "when logged in as the challenge owner" do
      let(:active_reader) { create(:user, username: "activereader") }
      let(:inactive_reader) { create(:user, username: "inactivereader") }

      before do
        create(:user_challenge_enrollment, user: active_reader, challenge: challenge)
        create(:user_challenge_enrollment, user: inactive_reader, challenge: challenge)
        # active_reader completes 2 of 10 (20%, below the old 50% threshold)
        readings.first(2).each do |reading|
          create(:user_reading, user: active_reader, reading: reading, completed_on: reading.scheduled_date)
        end
        login_via_session(owner)
      end

      it "returns success" do
        get challenge_manage_top_readers_path(challenge)
        expect(response).to have_http_status(:success)
      end

      it "lists readers with at least one completion, even below 50%" do
        get challenge_manage_top_readers_path(challenge)
        expect(response.body).to include("activereader")
      end

      it "excludes enrolled users who have completed nothing" do
        get challenge_manage_top_readers_path(challenge)
        expect(response.body).not_to include("inactivereader")
      end
    end

    context "when logged in as a non-manager" do
      let(:other_user) { create(:user) }
      before { login_via_session(other_user) }

      it "redirects with access denied" do
        get challenge_manage_top_readers_path(challenge)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get challenge_manage_top_readers_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
