require 'rails_helper'

RSpec.describe ChallengeInvitationsController, type: :controller do
  let(:challenge) { FactoryBot.create(:challenge, start_date: Date.yesterday, end_date: 10.days.from_now) }
  let(:user) { FactoryBot.create(:user) }

  describe 'GET #show' do
    context 'with valid invitation token' do
      it 'stores token in session and renders the show invitation template' do
        get :show, params: { token: challenge.invitation_token }

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)
      end
    end

    context 'with invalid invitation token' do
      it 'redirects to root with alert' do
        get :show, params: { token: 'INVALID' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Invalid invitation link.')
      end
    end
  end

  describe 'POST #accept' do
    context 'when user is not logged in' do
      it 'redirects to sign in' do
        post :accept, params: { token: challenge.invitation_token }

        expect(response).to redirect_to(new_user_session_path)
        expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)
      end
    end

    context 'when user is logged in' do
      before { log_in_user(user) }

      it 'enrolls user, sets active challenge, and redirects to reading page' do
        expect {
          post :accept, params: { token: challenge.invitation_token }
        }.to change(UserChallengeEnrollment, :count).by(1)

        expect(response).to redirect_to(reading_path)
        expect(flash[:notice]).to include("Successfully joined #{challenge.name}")
        expect(user.reload.challenges).to include(challenge)
        expect(session[:active_challenge_id]).to eq(challenge.id)
      end

      it 'allows enrolling when already enrolled in a different challenge' do
        other_challenge = FactoryBot.create(:challenge)
        FactoryBot.create(:user_challenge_enrollment, user: user, challenge: other_challenge)

        expect {
          post :accept, params: { token: challenge.invitation_token }
        }.to change(UserChallengeEnrollment, :count).by(1)

        expect(response).to redirect_to(reading_path)
        expect(user.reload.challenges).to include(challenge)
        expect(user.challenges).to include(other_challenge)
      end

      it 'redirects to reading if already enrolled in this challenge' do
        FactoryBot.create(:user_challenge_enrollment, user: user, challenge: challenge)

        expect {
          post :accept, params: { token: challenge.invitation_token }
        }.not_to change(UserChallengeEnrollment, :count)

        expect(response).to redirect_to(reading_path)
        expect(flash[:notice]).to include("You are already enrolled")
      end
    end
  end

  private

  def log_in_user(user)
    session[:user_id] = user.id
  end
end
