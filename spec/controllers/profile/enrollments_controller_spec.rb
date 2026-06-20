require 'rails_helper'

RSpec.describe Profile::EnrollmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:current_challenge) do
    create(:challenge,
      start_date: Date.current - 10.days,
      end_date: Date.current + 20.days,
      timezone: 'UTC')
  end
  let(:past_challenge) do
    create(:challenge,
      start_date: Date.current - 60.days,
      end_date: Date.current - 1.day,
      timezone: 'UTC')
  end
  let(:current_enrollment) { create(:user_challenge_enrollment, user: user, challenge: current_challenge) }
  let(:past_enrollment) { create(:user_challenge_enrollment, user: user, challenge: past_challenge) }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for index action' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for destroy action' do
        delete :destroy, params: { id: current_enrollment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'when user is logged in' do
    before do
      session[:user_id] = user.id
    end

    describe 'GET #index' do
      context 'when user has no enrollments' do
        it 'assigns empty current and past enrollment arrays' do
          get :index
          expect(assigns(:current_enrollments)).to be_empty
          expect(assigns(:past_enrollments)).to be_empty
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

      context 'when user has a current enrollment' do
        before { current_enrollment }

        it 'assigns to current_enrollments' do
          get :index
          expect(assigns(:current_enrollments)).to include(current_enrollment)
        end

        it 'assigns empty past_enrollments' do
          get :index
          expect(assigns(:past_enrollments)).to be_empty
        end

        it 'renders the index template' do
          get :index
          expect(response).to render_template(:index)
        end
      end

      context 'when user has a past enrollment' do
        before { past_enrollment }

        it 'assigns to past_enrollments' do
          get :index
          expect(assigns(:past_enrollments)).to include(past_enrollment)
        end

        it 'assigns empty current_enrollments' do
          get :index
          expect(assigns(:current_enrollments)).to be_empty
        end
      end

      context 'when user has both current and past enrollments' do
        before do
          current_enrollment
          past_enrollment
        end

        it 'splits enrollments correctly' do
          get :index
          expect(assigns(:current_enrollments)).to include(current_enrollment)
          expect(assigns(:past_enrollments)).to include(past_enrollment)
        end
      end
    end

    describe 'GET #show' do
      context 'for a past challenge' do
        before { past_enrollment }

        it 'returns successful response' do
          get :show, params: { id: past_enrollment.id }
          expect(response).to be_successful
        end

        it 'assigns challenge stats' do
          get :show, params: { id: past_enrollment.id }
          expect(assigns(:stats)).to be_present
        end
      end

      context 'for a current (non-past) challenge' do
        before { current_enrollment }

        it 'redirects to enrollments index' do
          get :show, params: { id: current_enrollment.id }
          expect(response).to redirect_to(profile_enrollments_path)
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'with valid enrollment belonging to user' do
        before { current_enrollment }

        it 'deletes the enrollment' do
          expect {
            delete :destroy, params: { id: current_enrollment.id }
          }.to change(user.user_challenge_enrollments, :count).by(-1)
        end

        it 'redirects to enrollments path' do
          delete :destroy, params: { id: current_enrollment.id }
          expect(response).to redirect_to(profile_enrollments_path)
        end
      end

      context 'when trying to delete another user\'s enrollment' do
        let(:other_user) { create(:user) }
        let(:other_user_enrollment) { create(:user_challenge_enrollment, user: other_user, challenge: current_challenge) }

        it 'raises RecordNotFound error' do
          other_user_enrollment
          expect {
            delete :destroy, params: { id: other_user_enrollment.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
