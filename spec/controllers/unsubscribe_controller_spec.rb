require 'rails_helper'

RSpec.describe UnsubscribeController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #show' do
    context 'with a valid token' do
      it 'logs the user in and redirects to email preferences' do
        token = user.create_unsubscribe_digest

        get :show, params: { token: token }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(edit_profile_email_preferences_path)
        expect(flash[:info]).to eq('You can manage your email preferences below')
      end

      it 'clears the unsubscribe token after use' do
        token = user.create_unsubscribe_digest

        get :show, params: { token: token }

        user.reload
        expect(user.unsubscribe_digest).to be_nil
        expect(user.unsubscribe_sent_at).to be_nil
      end
    end

    context 'with an invalid token' do
      it 'redirects to root with an error message' do
        get :show, params: { token: 'invalid_token' }

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('Unsubscribe link is invalid or has expired')
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with an expired token' do
      it 'redirects to root with an error message' do
        token = user.create_unsubscribe_digest
        user.update_column(:unsubscribe_sent_at, 25.hours.ago)

        get :show, params: { token: token }

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('Unsubscribe link is invalid or has expired')
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
