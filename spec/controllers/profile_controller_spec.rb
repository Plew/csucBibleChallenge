require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  let(:user) { create(:user) }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for index action' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'when user is logged in' do
    before { session[:user_id] = user.id }

    describe 'GET #index' do
      it 'assigns the current user' do
        get :index
        expect(assigns(:user)).to eq(user)
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'returns successful response' do
        get :index
        expect(response).to be_successful
      end
    end
  end

  context 'with user who has challenges' do
    let(:challenge) { create(:challenge) }
    let(:user_enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

    before do
      user_enrollment
      session[:user_id] = user.id
    end

    describe 'GET #index' do
      it 'assigns user with enrollment data accessible' do
        get :index
        assigned_user = assigns(:user)
        expect(assigned_user).to eq(user)
        expect(assigned_user.user_challenge_enrollments).to include(user_enrollment)
      end
    end
  end

  context 'with user who has completed readings' do
    let(:challenge) { create(:challenge) }
    let(:reading) { create(:reading, challenge: challenge) }
    let(:user_enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
    let!(:user_reading) { create(:user_reading, user: user, reading: reading) }

    before do
      user_enrollment
      session[:user_id] = user.id
    end

    describe 'GET #index' do
      it 'assigns user with reading progress accessible' do
        get :index
        assigned_user = assigns(:user)
        expect(assigned_user).to eq(user)
        expect(assigned_user.user_readings).to include(user_reading)
      end
    end
  end

  context 'security considerations' do
    let(:other_user) { create(:user) }

    before { session[:user_id] = user.id }

    it 'only shows current user data, not other users' do
      get :index
      assigned_user = assigns(:user)
      expect(assigned_user).to eq(user)
      expect(assigned_user).not_to eq(other_user)
    end

    it 'cannot access other user data through manipulation' do
      # Even if someone tried to manipulate the request, they should only see their own data
      get :index, params: { user_id: other_user.id }
      assigned_user = assigns(:user)
      expect(assigned_user).to eq(user)
      expect(assigned_user).not_to eq(other_user)
    end
  end
end
