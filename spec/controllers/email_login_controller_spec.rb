require 'rails_helper'

RSpec.describe EmailLoginController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:reading) { create(:reading, challenge: challenge) }

  describe 'GET #show' do
    context 'with a valid, never-used token' do
      let(:token) { create(:email_login_token, user: user, challenge: challenge, reading: reading, created_at: 1.hour.ago, clicked_at: nil) }

      it 'logs the user in' do
        get :show, params: { token: token.token }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'marks the token as clicked' do
        expect {
          get :show, params: { token: token.token }
        }.to change { token.reload.clicked_at }.from(nil)
      end

      it 'redirects to reading page' do
        get :show, params: { token: token.token }
        expect(response).to redirect_to(reading_path)
      end

      it 'sets a success notice' do
        get :show, params: { token: token.token }
        expect(flash[:notice]).to eq("You've been logged in successfully.")
      end
    end

    context 'with a previously used token still within 7 days' do
      let(:token) { create(:email_login_token, user: user, challenge: challenge, reading: reading, created_at: 1.day.ago, clicked_at: 12.hours.ago) }

      it 'logs the user in' do
        get :show, params: { token: token.token }
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to reading page' do
        get :show, params: { token: token.token }
        expect(response).to redirect_to(reading_path)
      end

      it 'does not overwrite the original clicked_at' do
        original_clicked_at = token.clicked_at
        get :show, params: { token: token.token }
        expect(token.reload.clicked_at).to be_within(1.second).of(original_clicked_at)
      end
    end

    context 'with a token created 6 days ago' do
      let(:token) { create(:email_login_token, user: user, challenge: challenge, reading: reading, created_at: 6.days.ago, clicked_at: 5.days.ago) }

      it 'still logs the user in' do
        get :show, params: { token: token.token }
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with an invalid token' do
      it 'redirects to root path' do
        get :show, params: { token: 'invalid_token' }
        expect(response).to redirect_to(root_path)
      end

      it 'sets an alert message' do
        get :show, params: { token: 'invalid_token' }
        expect(flash[:alert]).to eq("Invalid login link.")
      end

      it 'does not log the user in' do
        get :show, params: { token: 'invalid_token' }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with an expired token (older than 7 days)' do
      let(:token) { create(:email_login_token, user: user, challenge: challenge, reading: reading, created_at: 8.days.ago, clicked_at: nil) }

      it 'redirects to root path' do
        get :show, params: { token: token.token }
        expect(response).to redirect_to(root_path)
      end

      it 'sets an alert message' do
        get :show, params: { token: token.token }
        expect(flash[:alert]).to eq("This login link has expired.")
      end

      it 'does not log the user in' do
        get :show, params: { token: token.token }
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
