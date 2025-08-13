require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'GET #new' do
    context 'when user is not logged in' do
      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end

      it 'returns successful response' do
        get :new
        expect(response).to be_successful
      end
    end

    context 'when user is already logged in' do
      before { session[:user_id] = user.id }

      it 'redirects to root path' do
        get :new
        expect(response).to redirect_to(root_path)
      end

      it 'sets a notice message' do
        get :new
        expect(flash[:notice]).to eq('You are already logged in.')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_credentials) do
      {
        session: {
          email: 'test@example.com',
          password: 'password123'
        }
      }
    end

    let(:invalid_credentials) do
      {
        session: {
          email: 'test@example.com',
          password: 'wrong_password'
        }
      }
    end

    context 'with valid credentials' do
      it 'logs in the user' do
        post :create, params: valid_credentials
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to root path' do
        post :create, params: valid_credentials
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post :create, params: invalid_credentials
        expect(session[:user_id]).to be_nil
      end

      it 'renders the new template' do
        post :create, params: invalid_credentials
        expect(response).to render_template(:new)
      end

      it 'returns unprocessable entity status' do
        post :create, params: invalid_credentials
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets an alert flash message' do
        post :create, params: invalid_credentials
        expect(flash.now[:alert]).to eq('Invalid email/username or password combination')
      end
    end

    context 'with non-existent email' do
      let(:non_existent_credentials) do
        {
          session: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
      end

      it 'does not log in the user' do
        post :create, params: non_existent_credentials
        expect(session[:user_id]).to be_nil
      end

      it 'renders new template with error' do
        post :create, params: non_existent_credentials
        expect(response).to render_template(:new)
        expect(flash.now[:alert]).to eq('Invalid email/username or password combination')
      end
    end

    context 'with case insensitive email' do
      let(:case_insensitive_credentials) do
        {
          session: {
            email: 'TEST@EXAMPLE.COM',
            password: 'password123'
          }
        }
      end

      it 'logs in the user regardless of email case' do
        post :create, params: case_insensitive_credentials
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with nil email' do
      let(:nil_email_credentials) do
        {
          session: {
            email: nil,
            password: 'password123'
          }
        }
      end

      it 'handles nil email gracefully' do
        expect {
          post :create, params: nil_email_credentials
        }.not_to raise_error
      end

      it 'does not log in the user' do
        post :create, params: nil_email_credentials
        expect(session[:user_id]).to be_nil
      end

      it 'shows error message' do
        post :create, params: nil_email_credentials
        expect(flash.now[:alert]).to eq('Invalid email/username or password combination')
      end
    end

    context 'with empty credentials' do
      let(:empty_credentials) do
        {
          session: {
            email: '',
            password: ''
          }
        }
      end

      it 'does not log in the user' do
        post :create, params: empty_credentials
        expect(session[:user_id]).to be_nil
      end

      it 'shows error message' do
        post :create, params: empty_credentials
        expect(flash.now[:alert]).to eq('Invalid email/username or password combination')
      end
    end

    context 'when already logged in' do
      let(:other_user) { create(:user) }
      
      before { session[:user_id] = other_user.id }

      it 'overwrites the existing session with new user' do
        post :create, params: valid_credentials
        expect(session[:user_id]).to eq(user.id)
        expect(session[:user_id]).not_to eq(other_user.id)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is logged in' do
      before { session[:user_id] = user.id }

      it 'logs out the user' do
        delete :destroy
        expect(session[:user_id]).to be_nil
      end

      it 'redirects to root url' do
        delete :destroy
        expect(response).to redirect_to(root_url)
      end

      it 'sets a notice message' do
        delete :destroy
        expect(flash[:notice]).to eq('Logged out!')
      end
    end

    context 'when user is not logged in' do
      it 'redirects to root url' do
        delete :destroy
        expect(response).to redirect_to(root_url)
      end

      it 'sets a notice message' do
        delete :destroy
        expect(flash[:notice]).to eq('Logged out!')
      end

      it 'does not raise an error' do
        expect {
          delete :destroy
        }.not_to raise_error
      end
    end

    context 'with invalid session data' do
      before { session[:user_id] = 99999 } # Non-existent user ID

      it 'handles gracefully and logs out' do
        expect {
          delete :destroy
        }.not_to raise_error
        
        expect(session[:user_id]).to be_nil
      end
    end
  end
end