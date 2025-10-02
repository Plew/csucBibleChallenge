require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #new' do
    it 'assigns a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'returns successful response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    let(:invalid_attributes) do
      {
        username: '',
        email: 'invalid_email',
        password: 'password123',
        password_confirmation: 'different_password'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'creates user with correct attributes' do
        post :create, params: { user: valid_attributes }
        user = User.last
        expect(user.username).to eq('testuser')
        expect(user.email).to eq('test@example.com')
        expect(user.authenticate('password123')).to be_truthy
      end

      it 'logs in the user after successful registration' do
        post :create, params: { user: valid_attributes }
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'redirects to root path' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'renders the new template' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'assigns user with errors' do
        post :create, params: { user: invalid_attributes }
        expect(assigns(:user)).to be_a(User)
        expect(assigns(:user).errors).not_to be_empty
      end

      it 'does not log in the user' do
        post :create, params: { user: invalid_attributes }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'with avatar upload' do
      let(:avatar_file) { fixture_file_upload('test_avatar.png', 'image/png') }
      let(:valid_attributes_with_avatar) do
        valid_attributes.merge(avatar: avatar_file)
      end

      it 'creates user with avatar' do
        post :create, params: { user: valid_attributes_with_avatar }
        user = User.last
        expect(user.avatar).to be_attached
      end
    end

    context 'with duplicate email' do
      let!(:existing_user) { create(:user, email: 'test@example.com') }
      let(:duplicate_email_attributes) do
        {
          username: 'different_username',
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: { user: duplicate_email_attributes }
        }.not_to change(User, :count)
      end

      it 'renders new template with validation errors' do
        post :create, params: { user: duplicate_email_attributes }
        expect(response).to render_template(:new)
        expect(assigns(:user).errors[:email]).to include('has already been taken')
      end
    end

    context 'with duplicate username' do
      let!(:existing_user) { create(:user, username: 'testuser') }
      let(:duplicate_username_attributes) do
        {
          username: 'testuser',
          email: 'different@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: { user: duplicate_username_attributes }
        }.not_to change(User, :count)
      end

      it 'renders new template with validation errors' do
        post :create, params: { user: duplicate_username_attributes }
        expect(response).to render_template(:new)
        expect(assigns(:user).errors[:username]).to include('has already been taken')
      end
    end

    context 'parameter filtering' do
      it 'only permits allowed parameters' do
        malicious_attributes = valid_attributes.merge(
          admin: true, # Should be filtered out
          created_at: 1.year.ago # Should be filtered out
        )

        post :create, params: { user: malicious_attributes }
        user = User.last
        expect(user.admin).to be_falsey
        expect(user.created_at).not_to eq(1.year.ago.to_date)
      end
    end

    context 'when already logged in' do
      let(:existing_user) { create(:user) }

      before { session[:user_id] = existing_user.id }

      it 'still allows user creation' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'logs in the newly created user (overrides current session)' do
        post :create, params: { user: valid_attributes }
        expect(session[:user_id]).to eq(User.last.id)
        expect(session[:user_id]).not_to eq(existing_user.id)
      end
    end

    context 'with pending challenge enrollment' do
      let(:challenge) { create(:challenge) }

      before do
        session[:pending_challenge_id] = challenge.id
      end

      it 'auto-enrolls user in the challenge after signup' do
        post :create, params: { user: valid_attributes }
        user = User.last
        expect(user.challenges).to include(challenge)
      end

      it 'redirects to challenge show page with success message' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(challenge_path(challenge))
        expect(flash[:notice]).to eq("Joined!")
      end

      it 'clears the pending challenge from session' do
        post :create, params: { user: valid_attributes }
        expect(session[:pending_challenge_id]).to be_nil
      end

      it 'creates an enrollment record' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(UserChallengeEnrollment, :count).by(1)
      end
    end

    context 'with challenge invitation token' do
      let(:challenge) { create(:challenge) }

      before do
        session[:challenge_invitation_token] = challenge.invitation_token
      end

      it 'auto-enrolls user via invitation token' do
        post :create, params: { user: valid_attributes }
        user = User.last
        expect(user.challenges).to include(challenge)
      end

      it 'clears the invitation token from session' do
        post :create, params: { user: valid_attributes }
        expect(session[:challenge_invitation_token]).to be_nil
      end
    end
  end

  describe 'GET #new with challenge_id' do
    let(:challenge) { create(:challenge) }

    it 'stores challenge_id in session' do
      get :new, params: { challenge_id: challenge.id }
      expect(session[:pending_challenge_id]).to eq(challenge.id.to_s)
    end
  end
end