require 'rails_helper'

RSpec.describe Profile::EnrollmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:user_enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to login for index action' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for destroy action' do
        delete :destroy, params: { id: user_enrollment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'when user is logged in' do
    before do
      user # Force creation
      session[:user_id] = user.id
    end

    describe 'GET #index' do
      context 'when user has no enrollments' do
        it 'assigns nil for user_enrollment' do
          get :index
          expect(assigns(:user_enrollment)).to be_nil
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

      context 'when user has enrollments' do
        before { user_enrollment }

        it 'assigns the first user enrollment' do
          get :index
          expect(assigns(:user_enrollment)).to eq(user_enrollment)
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

      context 'when user has multiple enrollments' do
        let(:another_challenge) { create(:challenge) }
        let!(:first_enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge, created_at: 1.day.ago) }
        let!(:second_enrollment) { create(:user_challenge_enrollment, user: user, challenge: another_challenge, created_at: Time.current) }

        it 'assigns the first enrollment (based on default ordering)' do
          get :index
          # Note: This tests the current implementation which gets .first
          # The actual behavior depends on the default ordering of user_challenge_enrollments
          assigned_enrollment = assigns(:user_enrollment)
          expect([first_enrollment, second_enrollment]).to include(assigned_enrollment)
        end
      end
    end

    describe 'DELETE #destroy' do
      context 'with valid enrollment belonging to user' do
        before { user_enrollment }

        it 'deletes the enrollment' do
          expect {
            delete :destroy, params: { id: user_enrollment.id }
          }.to change(user.user_challenge_enrollments, :count).by(-1)
        end

        it 'destroys the specific enrollment' do
          delete :destroy, params: { id: user_enrollment.id }
          expect { user_enrollment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'redirects to profile enrollments path' do
          delete :destroy, params: { id: user_enrollment.id }
          expect(response).to redirect_to(profile_enrollments_path)
        end

        it 'sets a success notice' do
          delete :destroy, params: { id: user_enrollment.id }
          expect(flash[:notice]).to eq('Successfully left the challenge.')
        end
      end

      context 'when trying to delete another user\'s enrollment' do
        let(:other_user) { create(:user) }
        let(:other_user_enrollment) { create(:user_challenge_enrollment, user: other_user, challenge: challenge) }

        it 'does not delete the enrollment' do
          other_user_enrollment # Force creation
          expect {
            expect {
              delete :destroy, params: { id: other_user_enrollment.id }
            }.to raise_error(ActiveRecord::RecordNotFound)
          }.not_to change(UserChallengeEnrollment, :count)
        end

        it 'raises RecordNotFound error' do
          other_user_enrollment # Force creation
          expect {
            delete :destroy, params: { id: other_user_enrollment.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with non-existent enrollment id' do
        it 'raises RecordNotFound error' do
          expect {
            delete :destroy, params: { id: 99999 }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when user has multiple enrollments' do
        let(:another_challenge) { create(:challenge) }
        let!(:first_enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
        let!(:second_enrollment) { create(:user_challenge_enrollment, user: user, challenge: another_challenge) }

        it 'only deletes the specified enrollment' do
          delete :destroy, params: { id: first_enrollment.id }
          
          expect { first_enrollment.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { second_enrollment.reload }.not_to raise_error
        end

        it 'reduces enrollment count by 1' do
          expect {
            delete :destroy, params: { id: first_enrollment.id }
          }.to change(user.user_challenge_enrollments, :count).by(-1)
        end
      end
    end

    context 'base controller functionality' do
      before { user_enrollment }

      it 'has access to current_user_enrollment method' do
        get :index
        # This tests that the base controller method works
        expect(assigns(:user_enrollment)).to be_present
      end
    end
  end

  context 'security and edge cases' do
    let(:other_user) { create(:user) }
    
    before { session[:user_id] = user.id }

    it 'only shows current user enrollments in index' do
      user_enrollment
      other_enrollment = create(:user_challenge_enrollment, user: other_user, challenge: challenge)
      
      get :index
      assigned_enrollment = assigns(:user_enrollment)
      expect(assigned_enrollment).to eq(user_enrollment)
      expect(assigned_enrollment).not_to eq(other_enrollment)
    end

    it 'cannot delete enrollments through parameter manipulation' do
      other_enrollment = create(:user_challenge_enrollment, user: other_user, challenge: challenge)
      
      expect {
        expect {
          delete :destroy, params: { id: other_enrollment.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      }.not_to change(UserChallengeEnrollment, :count)
    end
  end
end