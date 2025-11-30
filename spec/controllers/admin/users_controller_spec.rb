require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:target_user) { create(:user, admin: false, username: 'testuser', email: 'test@example.com') }

  describe 'authorization' do
    context 'when user is not logged in' do
      it 'redirects to login for index action' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for show action' do
        get :show, params: { id: target_user.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for update_password action' do
        patch :update_password, params: { id: target_user.id, new_password: 'newpass123' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not an admin' do
      before { session[:user_id] = regular_user.id }

      it 'redirects to root for index action' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'redirects to root for show action' do
        get :show, params: { id: target_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'redirects to root for update_password action' do
        patch :update_password, params: { id: target_user.id, new_password: 'newpass123' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end
  end

  describe 'GET #index' do
    before { session[:user_id] = admin_user.id }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns all users ordered by created_at desc' do
      user1 = create(:user, created_at: 1.day.ago)
      user2 = create(:user, created_at: 2.days.ago)

      get :index

      expect(assigns(:users)).to be_present
      expect(assigns(:users).first.created_at).to be >= assigns(:users).last.created_at
    end

    it 'preloads challenges association' do
      get :index
      expect(assigns(:users).first.association(:challenges)).to be_loaded
    end

    context 'with search parameter' do
      let!(:user1) { create(:user, username: 'alice', email: 'alice@example.com') }
      let!(:user2) { create(:user, username: 'bob', email: 'bob@example.com') }

      it 'filters by email' do
        get :index, params: { search: 'alice' }
        expect(assigns(:users)).to include(user1)
        expect(assigns(:users)).not_to include(user2)
      end

      it 'filters by username' do
        get :index, params: { search: 'bob' }
        expect(assigns(:users)).to include(user2)
        expect(assigns(:users)).not_to include(user1)
      end

      it 'filters by user id' do
        get :index, params: { search: user1.id.to_s }
        expect(assigns(:users)).to include(user1)
        expect(assigns(:users)).not_to include(user2)
      end
    end
  end

  describe 'GET #show' do
    let(:challenge) { create(:challenge, timezone: 'Berlin') }
    let!(:enrollment) { create(:user_challenge_enrollment, user: target_user, challenge: challenge) }

    before { session[:user_id] = admin_user.id }

    it 'returns http success' do
      get :show, params: { id: target_user.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the user' do
      get :show, params: { id: target_user.id }
      expect(assigns(:user)).to eq(target_user)
    end

    it 'assigns challenge enrollments' do
      get :show, params: { id: target_user.id }
      expect(assigns(:challenge_enrollments)).to be_present
    end
  end

  describe 'GET #reading_history' do
    let(:challenge) { create(:challenge, timezone: 'Berlin') }
    let(:reading) { create(:reading, challenge: challenge) }
    let!(:user_reading) { create(:user_reading, user: target_user, reading: reading, completed_on: Time.current) }

    before { session[:user_id] = admin_user.id }

    it 'returns http success' do
      get :reading_history, params: { id: target_user.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the user' do
      get :reading_history, params: { id: target_user.id }
      expect(assigns(:user)).to eq(target_user)
    end

    it 'assigns user readings ordered by completed_on desc' do
      reading2 = create(:reading, challenge: challenge)
      user_reading2 = create(:user_reading, user: target_user, reading: reading2, completed_on: 1.day.ago)

      get :reading_history, params: { id: target_user.id }

      expect(assigns(:user_readings)).to be_present
      expect(assigns(:user_readings).first.completed_on).to be >= assigns(:user_readings).last.completed_on
    end

    it 'preloads reading and challenge associations' do
      get :reading_history, params: { id: target_user.id }

      user_reading = assigns(:user_readings).first
      expect(user_reading.association(:reading)).to be_loaded
      expect(user_reading.reading.association(:challenge)).to be_loaded
    end
  end

  describe 'GET #change_password' do
    before { session[:user_id] = admin_user.id }

    it 'returns http success' do
      get :change_password, params: { id: target_user.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns the user' do
      get :change_password, params: { id: target_user.id }
      expect(assigns(:user)).to eq(target_user)
    end
  end

  describe 'PATCH #update_password' do
    before { session[:user_id] = admin_user.id }

    context 'with valid password' do
      it 'updates the user password' do
        patch :update_password, params: { id: target_user.id, new_password: 'newpass123' }

        target_user.reload
        expect(target_user.authenticate('newpass123')).to be_truthy
      end

      it 'redirects to user show page with success message' do
        patch :update_password, params: { id: target_user.id, new_password: 'newpass123' }

        expect(response).to redirect_to(admin_user_path(target_user))
        expect(flash[:notice]).to eq('Password updated successfully')
      end

      it 'allows the user to log in with the new password' do
        patch :update_password, params: { id: target_user.id, new_password: 'newpass123' }

        target_user.reload
        expect(target_user.authenticate('newpass123')).to eq(target_user)
      end
    end

    context 'with blank password' do
      it 'does not update the password' do
        old_password_digest = target_user.password_digest

        patch :update_password, params: { id: target_user.id, new_password: '' }

        target_user.reload
        expect(target_user.password_digest).to eq(old_password_digest)
      end

      it 'redirects to user show page with error message' do
        patch :update_password, params: { id: target_user.id, new_password: '' }

        expect(response).to redirect_to(admin_user_path(target_user))
        expect(flash[:alert]).to eq('Password cannot be blank')
      end
    end

    context 'with password too short' do
      it 'does not update the password' do
        old_password_digest = target_user.password_digest

        patch :update_password, params: { id: target_user.id, new_password: 'short' }

        target_user.reload
        expect(target_user.password_digest).to eq(old_password_digest)
      end

      it 'redirects to user show page with error message' do
        patch :update_password, params: { id: target_user.id, new_password: 'short' }

        expect(response).to redirect_to(admin_user_path(target_user))
        expect(flash[:alert]).to eq('Password must be at least 6 characters')
      end
    end

    context 'with missing password parameter' do
      it 'does not update the password' do
        old_password_digest = target_user.password_digest

        patch :update_password, params: { id: target_user.id }

        target_user.reload
        expect(target_user.password_digest).to eq(old_password_digest)
      end

      it 'redirects to user show page with error message' do
        patch :update_password, params: { id: target_user.id }

        expect(response).to redirect_to(admin_user_path(target_user))
        expect(flash[:alert]).to eq('Password cannot be blank')
      end
    end
  end

  describe 'PATCH #reset_password' do
    before { session[:user_id] = admin_user.id }

    it 'generates a new random password' do
      patch :reset_password, params: { id: target_user.id }

      target_user.reload
      # The old password should no longer work
      expect(target_user.authenticate('password')).to be_falsey
    end

    it 'redirects to users index with success message and new password' do
      patch :reset_password, params: { id: target_user.id }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to match(/Password reset for #{target_user.email}. New password:/)
    end
  end
end
