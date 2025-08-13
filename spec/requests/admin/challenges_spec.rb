require 'rails_helper'

RSpec.describe "Admin::Challenges", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin/challenges/new" do
        get new_admin_challenge_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for POST /admin/challenges" do
        post admin_challenges_path, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/challenges/new" do
        get new_admin_challenge_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it "redirects to root for POST /admin/challenges" do
        post admin_challenges_path, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end
  end

  describe "GET /admin/challenges/new" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get new_admin_challenge_path
      expect(response).to have_http_status(:success)
    end

    it "displays the challenge creation form" do
      get new_admin_challenge_path
      expect(response.body).to include('Create New Reading Challenge')
      expect(response.body).to include('Challenge Title')
      expect(response.body).to include('Start Date')
      expect(response.body).to include('Select Bible Books')
    end
  end

  describe "POST /admin/challenges" do
    before { login_via_session(admin_user) }

    let(:valid_params) do
      {
        challenge: {
          name: 'Test Challenge',
          start_date: Date.current.to_s,
          timezone: 'UTC'
        },
        selected_books: ['40', '41'] # Matthew and Mark
      }
    end

    let(:invalid_params) do
      {
        challenge: {
          name: '',
          start_date: '',
          timezone: 'UTC'
        }
      }
    end

    context "with valid parameters" do
      it "creates a new challenge" do
        expect {
          post admin_challenges_path, params: valid_params
        }.to change(Challenge, :count).by(1)
      end

      it "creates readings for selected books" do
        expect {
          post admin_challenges_path, params: valid_params
        }.to change(Reading, :count).by(44) # Matthew (28) + Mark (16) = 44 chapters
      end

      it "redirects to root with success message" do
        post admin_challenges_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Challenge created successfully!')
      end
    end

    context "with invalid parameters" do
      it "does not create a challenge" do
        expect {
          post admin_challenges_path, params: invalid_params
        }.not_to change(Challenge, :count)
      end

      it "returns unprocessable entity status" do
        post admin_challenges_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "redisplays the form" do
        post admin_challenges_path, params: invalid_params
        expect(response.body).to include('Create New Reading Challenge')
      end
    end
  end

end