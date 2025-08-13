require 'rails_helper'

RSpec.describe Profile::PasswordsController, type: :controller do
  let(:user) { create(:user, password: 'current_password') }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for edit action' do
        get :edit
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for update action' do
        patch :update, params: { 
          user: { 
            current_password: 'current_password',
            password: 'new_password',
            password_confirmation: 'new_password'
          } 
        }
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
        expect(response).to render_template(:edit)
      end

      it 'returns successful response' do
        get :edit
        expect(response).to be_successful
      end
    end

    describe 'PATCH #update' do
      let(:valid_attributes) do
        {
          current_password: 'current_password',
          password: 'new_password123',
          password_confirmation: 'new_password123'
        }
      end

      context 'with valid parameters' do
        it 'updates the user password' do
          patch :update, params: { user: valid_attributes }
          user.reload
          expect(user.authenticate('new_password123')).to be_truthy
        end

        it 'redirects to edit password path' do
          patch :update, params: { user: valid_attributes }
          expect(response).to redirect_to(edit_profile_password_path)
        end

        it 'sets a success notice' do
          patch :update, params: { user: valid_attributes }
          expect(flash[:notice]).to eq('Password updated successfully.')
        end
      end

      context 'with incorrect current password' do
        let(:invalid_current_password_attributes) do
          {
            current_password: 'wrong_password',
            password: 'new_password123',
            password_confirmation: 'new_password123'
          }
        end

        it 'does not update the password' do
          patch :update, params: { user: invalid_current_password_attributes }
          user.reload
          expect(user.authenticate('new_password123')).to be_falsey
          expect(user.authenticate('current_password')).to be_truthy
        end

        it 'renders the edit template' do
          patch :update, params: { user: invalid_current_password_attributes }
          expect(response).to render_template(:edit)
        end

        it 'returns unprocessable entity status' do
          patch :update, params: { user: invalid_current_password_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with mismatched password confirmation' do
        let(:mismatched_confirmation_attributes) do
          {
            current_password: 'current_password',
            password: 'new_password123',
            password_confirmation: 'different_password'
          }
        end

        it 'does not update the password' do
          patch :update, params: { user: mismatched_confirmation_attributes }
          user.reload
          expect(user.authenticate('new_password123')).to be_falsey
          expect(user.authenticate('current_password')).to be_truthy
        end

        it 'renders the edit template' do
          patch :update, params: { user: mismatched_confirmation_attributes }
          expect(response).to render_template(:edit)
        end

        it 'returns unprocessable entity status' do
          patch :update, params: { user: mismatched_confirmation_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'assigns user with validation errors' do
          patch :update, params: { user: mismatched_confirmation_attributes }
          expect(assigns(:user).errors[:password_confirmation]).to include("doesn't match Password")
        end
      end

      context 'with weak password' do
        let(:weak_password_attributes) do
          {
            current_password: 'current_password',
            password: '123',
            password_confirmation: '123'
          }
        end

        it 'does not update the password' do
          patch :update, params: { user: weak_password_attributes }
          user.reload
          expect(user.authenticate('123')).to be_falsey
          expect(user.authenticate('current_password')).to be_truthy
        end

        it 'renders the edit template with validation errors' do
          patch :update, params: { user: weak_password_attributes }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with missing current password' do
        let(:missing_current_password_attributes) do
          {
            current_password: '',
            password: 'new_password123',
            password_confirmation: 'new_password123'
          }
        end

        it 'does not update the password' do
          patch :update, params: { user: missing_current_password_attributes }
          user.reload
          expect(user.authenticate('new_password123')).to be_falsey
          expect(user.authenticate('current_password')).to be_truthy
        end

        it 'renders the edit template' do
          patch :update, params: { user: missing_current_password_attributes }
          expect(response).to render_template(:edit)
        end
      end

      context 'parameter filtering' do
        it 'only permits password-related parameters' do
          patch :update, params: { 
            user: { 
              current_password: 'current_password',
              password: 'new_password123',
              password_confirmation: 'new_password123',
              username: 'hacker_attempt', # Should be filtered out
              email: 'hacker@example.com', # Should be filtered out
              admin: true # Should be filtered out
            }
          }
          user.reload
          expect(user.username).not_to eq('hacker_attempt')
          expect(user.email).not_to eq('hacker@example.com')
          expect(user.admin).to be_falsey
        end
      end
    end
  end
end