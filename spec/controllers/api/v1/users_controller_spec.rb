require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
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

      it 'returns created status' do
        post :create, params: { user: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'returns JSON response with user data' do
        post :create, params: { user: valid_attributes }
        json_response = JSON.parse(response.body)

        expect(json_response['username']).to eq('testuser')
        expect(json_response['email']).to eq('test@example.com')
        expect(json_response['id']).to be_present
      end

      it 'excludes password_digest from response' do
        post :create, params: { user: valid_attributes }
        json_response = JSON.parse(response.body)

        expect(json_response).not_to have_key('password_digest')
        expect(json_response).not_to have_key('password')
      end

      it 'includes timestamps in response' do
        post :create, params: { user: valid_attributes }
        json_response = JSON.parse(response.body)

        expect(json_response['created_at']).to be_present
        expect(json_response['updated_at']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns JSON with error messages' do
        post :create, params: { user: invalid_attributes }
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors']).not_to be_empty
      end

      it 'includes specific validation errors' do
        post :create, params: { user: invalid_attributes }
        json_response = JSON.parse(response.body)

        error_messages = json_response['errors']
        expect(error_messages).to include(match(/Username can't be blank/))
        expect(error_messages).to include(match(/Password confirmation doesn't match/))
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

      it 'returns unprocessable entity status' do
        post :create, params: { user: duplicate_email_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns error about email uniqueness' do
        post :create, params: { user: duplicate_email_attributes }
        json_response = JSON.parse(response.body)

        error_messages = json_response['errors']
        expect(error_messages).to include(match(/Email has already been taken/))
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

      it 'returns error about username uniqueness' do
        post :create, params: { user: duplicate_username_attributes }
        json_response = JSON.parse(response.body)

        error_messages = json_response['errors']
        expect(error_messages).to include(match(/Username has already been taken/))
      end
    end

    context 'parameter filtering' do
      it 'only permits allowed parameters' do
        malicious_attributes = valid_attributes.merge(
          admin: true, # Should be filtered out
          created_at: 1.year.ago, # Should be filtered out
          id: 123 # Should be filtered out
        )

        post :create, params: { user: malicious_attributes }
        user = User.last

        expect(user.admin).to be_falsey
        expect(user.id).not_to eq(123)
        expect(user.created_at).not_to eq(1.year.ago.to_date)
      end

      it 'creates user with only permitted attributes' do
        post :create, params: { user: valid_attributes }
        user = User.last

        expect(user.username).to eq('testuser')
        expect(user.email).to eq('test@example.com')
        expect(user.authenticate('password123')).to be_truthy
      end
    end

    context 'with missing parameters' do
      it 'handles missing user parameter gracefully' do
        expect {
          post :create, params: {}
        }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'edge cases' do
      it 'handles empty password confirmation' do
        attributes_with_empty_confirmation = valid_attributes.merge(
          password_confirmation: ''
        )

        post :create, params: { user: attributes_with_empty_confirmation }
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(match(/Password confirmation doesn't match/))
      end

      it 'handles very long username' do
        long_username = 'a' * 1000
        attributes_with_long_username = valid_attributes.merge(
          username: long_username
        )

        post :create, params: { user: attributes_with_long_username }
        # Behavior depends on User model validations
        # This test documents the current behavior
      end

      it 'handles invalid email format' do
        invalid_email_attributes = valid_attributes.merge(
          email: 'not_an_email'
        )

        post :create, params: { user: invalid_email_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'response format' do
      it 'returns JSON content type' do
        post :create, params: { user: valid_attributes }
        expect(response.content_type).to include('application/json')
      end

      it 'returns valid JSON' do
        post :create, params: { user: valid_attributes }
        expect {
          JSON.parse(response.body)
        }.not_to raise_error
      end
    end
  end
end
