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

  describe 'GET #index with inactive_days filter' do
    let(:challenge) { create(:challenge) }

    before { session[:user_id] = admin_user.id }

    it 'filters to show only users with no activity in the last 7 days' do
      active_user = create(:user, username: 'active_user')
      inactive_user = create(:user, username: 'inactive_user')

      reading = create(:reading, challenge: challenge, scheduled_date: 3.days.ago.to_date)
      create(:user_reading, user: active_user, reading: reading, completed_on: 3.days.ago.to_date)

      get :index, params: { inactive_days: 7 }

      expect(assigns(:users)).to include(inactive_user)
      expect(assigns(:users)).not_to include(active_user)
    end

    it 'filters to show only users with no activity in the last 10 days' do
      active_user = create(:user, username: 'active_user')
      inactive_user = create(:user, username: 'inactive_user')

      reading = create(:reading, challenge: challenge, scheduled_date: 5.days.ago.to_date)
      create(:user_reading, user: active_user, reading: reading, completed_on: 5.days.ago.to_date)

      get :index, params: { inactive_days: 10 }

      expect(assigns(:users)).to include(inactive_user)
      expect(assigns(:users)).not_to include(active_user)
    end

    it 'shows user with old activity when filtering by 7 days' do
      old_active_user = create(:user, username: 'old_active')
      old_reading = create(:reading, challenge: challenge, scheduled_date: 8.days.ago.to_date)
      create(:user_reading, user: old_active_user, reading: old_reading, completed_on: 8.days.ago.to_date)

      get :index, params: { inactive_days: 7 }

      expect(assigns(:users)).to include(old_active_user)
    end

    it 'does not show user with recent activity when filtering by 7 days' do
      recent_user = create(:user, username: 'recent_user')
      recent_reading = create(:reading, challenge: challenge, scheduled_date: 2.days.ago.to_date)
      create(:user_reading, user: recent_user, reading: recent_reading, completed_on: 2.days.ago.to_date)

      get :index, params: { inactive_days: 7 }

      expect(assigns(:users)).not_to include(recent_user)
    end

    it 'combines inactive filter with search' do
      inactive_user = create(:user, username: 'inactive_target', email: 'inactive_target@example.com')
      other_inactive = create(:user, username: 'other_inactive', email: 'other@example.com')

      get :index, params: { inactive_days: 7, search: 'inactive_target' }

      expect(assigns(:users)).to include(inactive_user)
      expect(assigns(:users)).not_to include(other_inactive)
    end
  end

  describe 'GET #index renders last 15 days activity' do
    render_views

    before { session[:user_id] = admin_user.id }

    it 'renders the index page successfully with activity data' do
      get :index
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Last 15 Days')
    end

    it 'renders activity squares for each user' do
      create(:user, username: 'graphuser')
      get :index
      # Each user should have 15 activity squares (w-2.5 h-2.5)
      expect(response.body).to include('bg-base-300')
    end
  end

  describe 'POST #remove_from_groups' do
    let(:challenge) { create(:challenge) }
    let(:group) { create(:group, challenge: challenge) }
    let!(:user1) { create(:user, username: 'groupuser1') }
    let!(:user2) { create(:user, username: 'groupuser2') }
    let!(:user3) { create(:user, username: 'groupuser3') }

    before do
      session[:user_id] = admin_user.id
      create(:user_group_enrollment, user: user1, group: group)
      create(:user_group_enrollment, user: user2, group: group)
      create(:user_group_enrollment, user: user3, group: group)
    end

    it 'removes selected users from their groups' do
      expect {
        post :remove_from_groups, params: { user_ids: [ user1.id, user2.id ] }
      }.to change(UserGroupEnrollment, :count).by(-2)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to include('Removed')
    end

    it 'does not remove unselected users from their groups' do
      post :remove_from_groups, params: { user_ids: [ user1.id ] }

      expect(UserGroupEnrollment.exists?(user_id: user2.id)).to be true
      expect(UserGroupEnrollment.exists?(user_id: user3.id)).to be true
    end

    it 'handles empty user_ids' do
      expect {
        post :remove_from_groups, params: { user_ids: [] }
      }.not_to change(UserGroupEnrollment, :count)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include('No users selected')
    end

    it 'handles missing user_ids param' do
      expect {
        post :remove_from_groups
      }.not_to change(UserGroupEnrollment, :count)

      expect(response).to redirect_to(admin_users_path)
    end

    it 'requires admin authentication' do
      session[:user_id] = nil
      post :remove_from_groups, params: { user_ids: [ user1.id ] }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'denies access to non-admin users' do
      session[:user_id] = regular_user.id
      post :remove_from_groups, params: { user_ids: [ user1.id ] }
      expect(response).to redirect_to(root_path)
    end
  end
end
