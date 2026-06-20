# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SevenDayLobbies', type: :request do
  let(:challenge) { create(:challenge, timezone: 'UTC') }
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }

  before do
    # Enroll user in challenge
    create(:user_challenge_enrollment, user: user, challenge: challenge)
    create(:user_challenge_enrollment, user: admin_user, challenge: challenge)
  end

  describe 'GET /challenges/:challenge_id/seven_day_win' do
    context 'when user is logged in and enrolled' do
      before { sign_in user }

      it 'returns http success' do
        get challenge_seven_day_lobby_path(challenge)
        expect(response).to have_http_status(:success)
      end

      it 'displays the lobby page' do
        get challenge_seven_day_lobby_path(challenge)
        expect(response.body).to include(I18n.t('seven_day_lobby.title'))
      end

      it 'shows participants in the lobby' do
        other_user = create(:user)
        create(:user_challenge_enrollment, user: other_user, challenge: challenge)
        create(:seven_day_lobby, challenge: challenge, user: other_user)

        get challenge_seven_day_lobby_path(challenge)
        expect(response.body).to include(other_user.name)
      end
    end

    context 'when user is not enrolled in challenge' do
      let(:non_enrolled_user) { create(:user) }

      before { sign_in non_enrolled_user }

      it 'redirects with an error' do
        get challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenges_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.must_be_enrolled'))
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login' do
        get challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /challenges/:challenge_id/seven_day_win/join' do
    before { sign_in user }

    context 'when user qualifies (100% completion)' do
      before do
        # Mock the qualification check to return true
        allow_any_instance_of(SevenDayLobbiesController)
          .to receive(:user_qualifies_for_lobby?).and_return(true)
      end

      it 'adds user to the lobby' do
        expect {
          post join_challenge_seven_day_lobby_path(challenge)
        }.to change(SevenDayLobby, :count).by(1)

        expect(SevenDayLobby.last.user).to eq(user)
        expect(SevenDayLobby.last.challenge).to eq(challenge)
      end

      it 'redirects with success message' do
        post join_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.joined_successfully'))
      end

      it 'does not create duplicate entries' do
        create(:seven_day_lobby, user: user, challenge: challenge)

        expect {
          post join_challenge_seven_day_lobby_path(challenge)
        }.not_to change(SevenDayLobby, :count)
      end
    end

    context 'when user does not qualify' do
      before do
        # Mock the qualification check to return false
        allow_any_instance_of(SevenDayLobbiesController)
          .to receive(:user_qualifies_for_lobby?).and_return(false)
      end

      it 'does not add user to lobby' do
        expect {
          post join_challenge_seven_day_lobby_path(challenge)
        }.not_to change(SevenDayLobby, :count)
      end

      it 'redirects with error message' do
        post join_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.not_qualified'))
      end
    end
  end

  describe 'DELETE /challenges/:challenge_id/seven_day_win/leave' do
    before do
      sign_in user
      create(:seven_day_lobby, user: user, challenge: challenge)
    end

    it 'removes user from the lobby' do
      expect {
        delete leave_challenge_seven_day_lobby_path(challenge)
      }.to change(SevenDayLobby, :count).by(-1)

      expect(SevenDayLobby.where(user: user, challenge: challenge)).to be_empty
    end

    it 'redirects with success message' do
      delete leave_challenge_seven_day_lobby_path(challenge)
      expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
      follow_redirect!
      expect(response.body).to include(I18n.t('seven_day_lobby.left_successfully'))
    end

    context 'when user is not in lobby' do
      before do
        SevenDayLobby.destroy_all
      end

      it 'does not raise an error' do
        expect {
          delete leave_challenge_seven_day_lobby_path(challenge)
        }.not_to change(SevenDayLobby, :count)
      end
    end
  end

  describe 'POST /challenges/:challenge_id/seven_day_win/start' do
    let(:participant1) { create(:user) }
    let(:participant2) { create(:user) }

    before do
      sign_in admin_user
      create(:user_challenge_enrollment, user: participant1, challenge: challenge)
      create(:user_challenge_enrollment, user: participant2, challenge: challenge)
      create(:seven_day_lobby, user: participant1, challenge: challenge)
      create(:seven_day_lobby, user: participant2, challenge: challenge)
    end

    context 'when user is admin' do
      it 'redirects to draw page with participants' do
        post start_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_manage_seven_day_winner_draw_path(
          challenge,
          user_ids: [ participant1.id, participant2.id ],
          animation_type: "pacman"
        ))
      end

      it 'clears the lobby when game starts' do
        expect {
          post start_challenge_seven_day_lobby_path(challenge)
        }.to change { SevenDayLobby.where(challenge: challenge).count }.from(2).to(0)
      end
    end

    context 'when user is the challenge owner (non-admin)' do
      before do
        create(:user_challenge_enrollment, user: challenge.creator, challenge: challenge)
        sign_in challenge.creator
      end

      it 'allows starting the draw' do
        post start_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_manage_seven_day_winner_draw_path(
          challenge,
          user_ids: [ participant1.id, participant2.id ],
          animation_type: "pacman"
        ))
      end
    end

    context 'when user is not admin or owner' do
      before { sign_in user }

      it 'redirects with error message' do
        post start_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.admin_only'))
      end
    end

    context 'when lobby is empty' do
      before do
        SevenDayLobby.destroy_all
      end

      it 'redirects with error message' do
        post start_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.no_participants'))
      end
    end
  end

  describe 'DELETE /challenges/:challenge_id/seven_day_win/clear_lobby' do
    let(:participant1) { create(:user) }
    let(:participant2) { create(:user) }

    before do
      create(:user_challenge_enrollment, user: participant1, challenge: challenge)
      create(:user_challenge_enrollment, user: participant2, challenge: challenge)
      create(:seven_day_lobby, user: participant1, challenge: challenge)
      create(:seven_day_lobby, user: participant2, challenge: challenge)
    end

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'removes all participants from the lobby' do
        expect {
          delete clear_lobby_challenge_seven_day_lobby_path(challenge)
        }.to change { SevenDayLobby.where(challenge: challenge).count }.from(2).to(0)
      end

      it 'redirects with success message' do
        delete clear_lobby_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.lobby_cleared'))
      end
    end

    context 'when user is not admin' do
      before { sign_in user }

      it 'redirects with error message' do
        delete clear_lobby_challenge_seven_day_lobby_path(challenge)
        expect(response).to redirect_to(challenge_seven_day_lobby_path(challenge))
        follow_redirect!
        expect(response.body).to include(I18n.t('seven_day_lobby.admin_only'))
      end

      it 'does not clear the lobby' do
        expect {
          delete clear_lobby_challenge_seven_day_lobby_path(challenge)
        }.not_to change { SevenDayLobby.where(challenge: challenge).count }
      end
    end
  end

  # Helper method to sign in users
  def sign_in(user)
    post user_session_path, params: { session: { email: user.email, password: user.password } }
  end
end
