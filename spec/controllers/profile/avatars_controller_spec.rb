require 'rails_helper'

RSpec.describe Profile::AvatarsController, type: :controller do
  let(:user) { create(:user) }
  let(:avatar_file) { fixture_file_upload('test_avatar.png', 'image/png') }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for edit action' do
        get :edit
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for update action' do
        patch :update, params: { user: { avatar: avatar_file } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for destroy action' do
        delete :destroy
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
      context 'with valid avatar' do
        it 'attaches the avatar to current user' do
          patch :update, params: { user: { avatar: avatar_file } }
          user.reload
          expect(user.avatar).to be_attached
        end

        it 'redirects to edit_profile_avatar_path with notice' do
          patch :update, params: { user: { avatar: avatar_file } }
          expect(response).to redirect_to(edit_profile_avatar_path)
          expect(flash[:notice]).to eq('Avatar updated successfully.')
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'when user has an attached avatar' do
        before do
          user.avatar.attach(
            io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_avatar.png')),
            filename: 'test_avatar.png',
            content_type: 'image/png'
          )
        end

        it 'removes the attached avatar' do
          expect(user.avatar).to be_attached
          delete :destroy
          user.reload
          expect(user.avatar).not_to be_attached
        end

        it 'redirects to edit_profile_avatar_path with notice' do
          delete :destroy
          expect(response).to redirect_to(edit_profile_avatar_path)
          expect(flash[:notice]).to eq('Profile picture removed successfully.')
        end
      end

      context 'when user does not have an attached avatar' do
        it 'does not raise error and redirects with notice' do
          expect(user.avatar).not_to be_attached
          delete :destroy
          user.reload
          expect(user.avatar).not_to be_attached
          expect(response).to redirect_to(edit_profile_avatar_path)
          expect(flash[:notice]).to eq('Profile picture removed successfully.')
        end
      end
    end
  end
end
