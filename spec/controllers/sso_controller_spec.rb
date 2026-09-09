require 'rails_helper'
require 'openssl'
require 'base64'
require 'json'

RSpec.describe SsoController, type: :controller do
  let(:secret) { "test_sso_secret_key_12345" }
  let(:user) { create(:user, email: "john@example.com", username: "johndoe") }
  let(:challenge) { create(:challenge) }

  def build_jwt(payload, key = secret)
    header = Base64.urlsafe_encode64({ alg: "HS256", typ: "JWT" }.to_json, padding: false)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)
    sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("sha256", key, "#{header}.#{body}"), padding: false)
    "#{header}.#{body}.#{sig}"
  end

  describe 'GET #authorize' do
    context 'when user is not logged in' do
      it 'stores return_to in session and redirects to login' do
        get :authorize, params: { return_to: 'https://campushub.org/sso/callback' }
        expect(session[:sso_return_to]).to eq('https://campushub.org/sso/callback')
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is logged in' do
      before { session[:user_id] = user.id }

      it 'generates a signed JWT and redirects to return_to with token' do
        get :authorize, params: { return_to: 'https://campushub.org/sso/callback' }
        expect(response).to be_redirect
        expect(response.location).to start_with('https://campushub.org/sso/callback?token=')

        token = response.location.split('token=').last
        parts = token.split('.')
        expect(parts.length).to eq(3)

        payload = JSON.parse(Base64.urlsafe_decode64(parts[1]))
        expect(payload['email']).to eq(user.email)
        expect(payload['name']).to eq(user.username)
        expect(payload['sub']).to eq(user.id.to_s)
      end
    end
  end

  describe 'GET #login' do
    context 'when token is missing' do
      it 'redirects to sign in with alert' do
        get :login
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('SSO token is missing.')
      end
    end

    context 'when token is invalid or tampered' do
      it 'redirects to sign in with alert' do
        token = build_jwt({ email: 'bad@example.com' }, 'wrong_secret_key')
        get :login, params: { token: token }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('Invalid SSO token or signature.')
      end
    end

    context 'when token is expired' do
      it 'redirects to sign in with alert' do
        token = build_jwt({ email: 'expired@example.com', exp: 10.minutes.ago.to_i })
        get :login, params: { token: token }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('expired')
      end
    end

    context 'when token has no email' do
      it 'redirects to sign in with alert' do
        token = build_jwt({ name: 'nameless', exp: 1.hour.from_now.to_i })
        get :login, params: { token: token }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('SSO token must include an email address.')
      end
    end

    context 'with valid token for existing user' do
      it 'logs in the existing user and redirects to reading' do
        token = build_jwt({
          email: user.email,
          name: 'Different Name',
          exp: 1.hour.from_now.to_i
        })

        get :login, params: { token: token }

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(reading_path)
        expect(flash[:notice]).to eq('Signed in successfully via SSO.')
      end

      it 'respects safe custom return_to' do
        token = build_jwt({
          email: user.email,
          exp: 1.hour.from_now.to_i
        })

        get :login, params: { token: token, return_to: '/challenges' }
        expect(response).to redirect_to('/challenges')
      end

      it 'rejects unsafe open redirect URLs' do
        token = build_jwt({
          email: user.email,
          exp: 1.hour.from_now.to_i
        })

        get :login, params: { token: token, return_to: 'https://malicious.com' }
        expect(response).to redirect_to(reading_path)
      end
    end

    context 'with valid token for new user' do
      it 'auto-provisions the user and logs them in' do
        new_email = 'newbie@example.com'
        expect(User.find_by(email: new_email)).to be_nil

        token = build_jwt({
          email: new_email,
          name: 'Sarah Connor',
          exp: 1.hour.from_now.to_i
        })

        expect {
          get :login, params: { token: token }
        }.to change(User, :count).by(1)

        created_user = User.find_by(email: new_email)
        expect(created_user).to be_present
        expect(created_user.username).to start_with('Sarah_Connor')
        expect(session[:user_id]).to eq(created_user.id)
        expect(response).to redirect_to(reading_path)
      end
    end

    context 'with challenge_id in token' do
      it 'auto-enrolls the user into the challenge' do
        token = build_jwt({
          email: user.email,
          challenge_id: challenge.id,
          exp: 1.hour.from_now.to_i
        })

        expect {
          get :login, params: { token: token }
        }.to change(user.challenges, :count).by(1)

        expect(user.challenges).to include(challenge)
        expect(session[:active_challenge_id]).to eq(challenge.id)
      end
    end

    context 'with embed=true' do
      it 'sets session[:embedded] and preserves embed parameter on redirect' do
        token = build_jwt({
          email: user.email,
          exp: 1.hour.from_now.to_i
        })

        get :login, params: { token: token, embed: 'true' }

        expect(session[:embedded]).to be true
        expect(response).to redirect_to('/reading?embed=true')
      end
    end

    context 'with paired CampusConnection' do
      let!(:campus_connection) do
        CampusConnection.create!(
          user: user,
          campus_name: 'Christian Students at UC',
          hub_url: 'https://uc-campushub.org',
          sso_secret: 'campus_specific_secret_999',
          challenge: challenge
        )
      end

      it 'verifies token signed with campus secret and auto-enrolls in campus challenge' do
        token = build_jwt({
          email: 'student@uc.edu',
          campus_url: 'https://uc-campushub.org',
          exp: 1.hour.from_now.to_i
        }, 'campus_specific_secret_999')

        get :login, params: { token: token }

        created_student = User.find_by(email: 'student@uc.edu')
        expect(created_student).to be_present
        expect(session[:user_id]).to eq(created_student.id)
        expect(created_student.challenges).to include(challenge)
        expect(response).to redirect_to(reading_path)
      end
    end
  end

  describe 'POST #login' do
    it 'accepts token via POST without CSRF token failure' do
      token = build_jwt({
        email: user.email,
        exp: 1.hour.from_now.to_i
      })

      post :login, params: { token: token }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(reading_path)
    end
  end
end
