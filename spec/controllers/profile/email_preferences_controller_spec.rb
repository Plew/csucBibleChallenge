require 'rails_helper'

RSpec.describe Profile::EmailPreferencesController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for edit action' do
        get :edit
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for update action' do
        patch :update, params: { user: { daily_email: false } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'when user is logged in' do
    before { session[:user_id] = user.id }

    describe 'GET #edit' do
      it 'assigns the current user' do
        get :edit
        expect(assigns(:user)).to eq(user)
      end

      it 'renders the edit template' do
        get :edit
        expect(response).to render_template('edit')
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH #update' do
      context 'with valid parameters' do
        it 'updates the user daily_email preference to false' do
          patch :update, params: { user: { daily_email: false } }
          user.reload
          expect(user.daily_email).to be_falsey
        end

        it 'updates the user daily_email preference to true' do
          user.update_columns(daily_email: false)
          patch :update, params: { user: { daily_email: true } }
          user.reload
          expect(user.daily_email).to be_truthy
        end

        it 'redirects to edit page with success notice' do
          patch :update, params: { user: { daily_email: false } }
          expect(response).to redirect_to(edit_profile_email_preferences_path)
          expect(flash[:notice]).to eq('Email preferences updated successfully.')
        end
      end

      context 'with checkbox unchecked (param not sent)' do
        it 'sets daily_email to false when checkbox is unchecked' do
          user.update_columns(daily_email: true)
          patch :update, params: { user: {} }
          user.reload
          expect(user.daily_email).to be_falsey
        end
      end

      it 'assigns the current user' do
        patch :update, params: { user: { daily_email: false } }
        expect(assigns(:user)).to eq(user)
      end

      it 'only updates the current user' do
        other_user.update_columns(daily_email: true)
        patch :update, params: { user: { daily_email: false } }
        
        user.reload
        other_user.reload
        
        expect(user.daily_email).to be_falsey
        expect(other_user.daily_email).to be_truthy
      end
    end
  end
end