require 'rails_helper'

RSpec.describe "Manage::SevenDayWinner", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }
  let(:participant) { create(:user) }

  before do
    create(:user_challenge_enrollment, user: participant, challenge: challenge)
  end

  describe "GET /challenges/:challenge_id/manage/seven_day_winner/draw" do
    let(:draw_path) { challenge_manage_seven_day_winner_draw_path(challenge, user_ids: [ participant.id ], animation_type: "pile") }

    context "as the challenge owner" do
      before { login_via_session(owner) }

      it "returns success" do
        get draw_path
        expect(response).to have_http_status(:success)
      end

      it "renders the draw page with the participant" do
        get draw_path
        expect(response.body).to include(participant.username)
      end
    end

    context "as a site admin" do
      let(:admin_user) { create(:user, :admin) }
      before { login_via_session(admin_user) }

      it "returns success" do
        get draw_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as a challenge organizer" do
      let(:organizer) { create(:user) }
      before do
        create(:user_challenge_enrollment, :organizer, user: organizer, challenge: challenge)
        login_via_session(organizer)
      end

      it "returns success" do
        get draw_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as a non-managing enrolled user" do
      before { login_via_session(participant) }

      it "redirects with access denied" do
        get draw_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get draw_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
