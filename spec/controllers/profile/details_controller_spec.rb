require 'rails_helper'

RSpec.describe Profile::DetailsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for edit action' do
        get :edit
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for update action' do
        patch :update, params: { user: { username: 'newname' } }
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
          username: 'updated_username',
          version: 'ESV'
        }
      end

      let(:invalid_attributes) do
        {
          username: '', # Invalid - username required
          version: 'ESV'
        }
      end

      context 'with valid parameters' do
        it 'updates the user' do
          patch :update, params: { user: valid_attributes }
          user.reload
          expect(user.username).to eq('updated_username')
          expect(user.version).to eq('ESV')
        end

        it 'redirects to edit profile details path' do
          patch :update, params: { user: valid_attributes }
          expect(response).to redirect_to(edit_profile_details_path)
        end

        it 'sets a success notice' do
          patch :update, params: { user: valid_attributes }
          expect(flash[:notice]).to eq('Profile details updated successfully.')
        end
      end

      context 'with invalid parameters' do
        it 'does not update the user' do
          original_username = user.username
          patch :update, params: { user: invalid_attributes }
          user.reload
          expect(user.username).to eq(original_username)
        end

        it 'renders the edit template' do
          patch :update, params: { user: invalid_attributes }
          expect(response).to render_template(:edit)
        end

        it 'returns unprocessable entity status' do
          patch :update, params: { user: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'assigns the user with errors' do
          patch :update, params: { user: invalid_attributes }
          expect(assigns(:user)).to eq(user)
          expect(assigns(:user).errors).not_to be_empty
        end
      end

      context 'with avatar upload' do
        let(:avatar_file) { fixture_file_upload('test_avatar.png', 'image/png') }

        it 'updates the user with avatar' do
          patch :update, params: { user: { username: user.username, avatar: avatar_file } }
          user.reload
          expect(user.avatar).to be_attached
        end
      end

      context 'parameter filtering' do
        it 'only permits allowed parameters' do
          patch :update, params: {
            user: {
              username: 'allowed',
              version: 'ESV',
              avatar: nil,
              email: 'not_allowed@example.com', # Should be filtered out
              admin: true # Should be filtered out
            }
          }
          user.reload
          expect(user.username).to eq('allowed')
          expect(user.version).to eq('ESV')
          expect(user.email).not_to eq('not_allowed@example.com')
          expect(user.admin).to be_falsey
        end
      end
    end
  end
end
