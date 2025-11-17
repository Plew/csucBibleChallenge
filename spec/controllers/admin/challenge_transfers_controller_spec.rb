require 'rails_helper'

RSpec.describe Admin::ChallengeTransfersController, type: :controller do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  before { session[:user_id] = admin_user.id }

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns all challenges' do
      challenge1 = create(:challenge)
      challenge2 = create(:challenge)
      get :new
      expect(assigns(:challenges)).to match_array([ challenge1, challenge2 ])
    end
  end

  describe 'POST #create' do
    let!(:from_challenge) { create(:challenge, name: 'Old Challenge') }
    let!(:to_challenge) { create(:challenge, name: 'New Challenge') }

    context 'when service call succeeds without errors' do
      let!(:user) { create(:user) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: from_challenge) }

      it 'redirects to admin_change_challenge_path with success notice' do
        post :create, params: {
          from_challenge_id: from_challenge.id,
          to_challenge_id: to_challenge.id
        }

        expect(response).to redirect_to(admin_change_challenge_path)
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('Successfully transferred')
      end
    end

    context 'when service call fails' do
      it 'redirects with alert message' do
        post :create, params: {
          from_challenge_id: from_challenge.id,
          to_challenge_id: from_challenge.id
        }

        expect(response).to redirect_to(admin_change_challenge_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when service has errors' do
      before do
        allow_any_instance_of(ChallengeTransferService).to receive(:errors).and_return([ 'Test error' ])
      end

      it 'redirects with error message' do
        post :create, params: {
          from_challenge_id: from_challenge.id,
          to_challenge_id: to_challenge.id
        }

        expect(response).to redirect_to(admin_change_challenge_path)
        expect(flash[:alert]).to include('Transfer completed with errors')
      end
    end
  end
end
