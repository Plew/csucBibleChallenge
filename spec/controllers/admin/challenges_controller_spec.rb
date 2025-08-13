require 'rails_helper'

RSpec.describe Admin::ChallengesController, type: :controller do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  describe 'authorization' do
    context 'when user is not logged in' do
      it 'redirects to login for new action' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for create action' do
        post :create, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not an admin' do
      before { session[:user_id] = regular_user.id }

      it 'redirects to root for new action' do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end

      it 'redirects to root for create action' do
        post :create, params: { challenge: { name: 'Test' } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied.')
      end
    end
  end

  describe 'GET #new' do
    before { session[:user_id] = admin_user.id }

    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new challenge' do
      get :new
      expect(assigns(:challenge)).to be_a_new(Challenge)
    end

    it 'loads bible books' do
      get :new
      expect(assigns(:bible_books)).to be_present
      expect(assigns(:bible_books).first).to have_key(:name)
      expect(assigns(:bible_books).first).to have_key(:chapters)
      expect(assigns(:bible_books).first).to have_key(:testament)
    end
  end

  describe 'POST #create' do
    before { session[:user_id] = admin_user.id }

    let(:valid_params) do
      {
        challenge: {
          name: 'Test Challenge',
          start_date: Date.current,
          timezone: 'UTC'
        },
        selected_books: ['40', '41'] # Matthew and Mark
      }
    end

    let(:invalid_params) do
      {
        challenge: {
          name: '',
          start_date: nil,
          timezone: 'UTC'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new challenge' do
        expect {
          post :create, params: valid_params
        }.to change(Challenge, :count).by(1)
      end

      it 'creates readings for selected books' do
        expect {
          post :create, params: valid_params
        }.to change(Reading, :count).by(44) # Matthew (28) + Mark (16) = 44 chapters
      end

      it 'sets the correct end date' do
        post :create, params: valid_params
        challenge = Challenge.last
        expected_end_date = challenge.start_date + 43.days # 44 chapters - 1 day
        expect(challenge.end_date).to eq(expected_end_date)
      end

      it 'redirects to root with success message' do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Challenge created successfully!')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a challenge' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Challenge, :count)
      end

      it 'renders new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'loads bible books for re-rendering' do
        post :create, params: invalid_params
        expect(assigns(:bible_books)).to be_present
      end
    end

    context 'with no selected books' do
      it 'creates challenge but no readings' do
        params = valid_params.tap { |p| p.delete(:selected_books) }
        
        expect {
          post :create, params: params
        }.to change(Challenge, :count).by(1)
        
        expect(Reading.count).to eq(0)
      end
    end
  end
end