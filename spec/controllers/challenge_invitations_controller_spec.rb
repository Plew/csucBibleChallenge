require 'rails_helper'

RSpec.describe ChallengeInvitationsController, type: :controller do
  let(:challenge) { FactoryBot.create(:challenge) }
  let(:user) { FactoryBot.create(:user) }

  describe 'GET #show' do
    context 'with valid invitation token' do
      context 'when user is not logged in' do
        it 'stores token in session and redirects to challenge show page' do
          get :show, params: { token: challenge.invitation_token }

          expect(response).to redirect_to(challenge_path(challenge))
          expect(session[:challenge_invitation_token]).to eq(challenge.invitation_token)
        end
      end

      context 'when user is logged in' do
        before { log_in_user(user) }

        context 'and user is not enrolled in any challenge' do
          it 'auto-enrolls user and redirects to reading page' do
            expect {
              get :show, params: { token: challenge.invitation_token }
            }.to change(UserChallengeEnrollment, :count).by(1)

            expect(response).to redirect_to(reading_path)
            expect(flash[:notice]).to include("Successfully joined #{challenge.name}")
            expect(user.reload.challenges).to include(challenge)
          end
        end

        context 'and user is already enrolled in this challenge' do
          before { FactoryBot.create(:user_challenge_enrollment, user: user, challenge: challenge) }

          it 'redirects to reading page with notice' do
            expect {
              get :show, params: { token: challenge.invitation_token }
            }.not_to change(UserChallengeEnrollment, :count)

            expect(response).to redirect_to(reading_path)
            expect(flash[:notice]).to include("You are already enrolled in #{challenge.name}")
          end
        end

        context 'and user is enrolled in a different challenge' do
          let(:other_challenge) { FactoryBot.create(:challenge, creator: FactoryBot.create(:user)) }
          before { FactoryBot.create(:user_challenge_enrollment, user: user, challenge: other_challenge) }

          it 'redirects to root with alert' do
            expect {
              get :show, params: { token: challenge.invitation_token }
            }.not_to change(UserChallengeEnrollment, :count)

            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to include('You are already enrolled in a challenge')
          end
        end

        context 'when enrollment fails' do
          before do
            allow_any_instance_of(UserChallengeEnrollment).to receive(:save).and_return(false)
            allow_any_instance_of(UserChallengeEnrollment).to receive(:errors).and_return(
              double(full_messages: [ 'Some error occurred' ])
            )
          end

          it 'redirects to root with error message' do
            get :show, params: { token: challenge.invitation_token }

            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to include('Could not join challenge')
          end
        end
      end
    end

    context 'with invalid invitation token' do
      it 'redirects to root with alert' do
        get :show, params: { token: 'INVALID' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Invalid invitation link.')
      end
    end
  end

  private

  def log_in_user(user)
    session[:user_id] = user.id
  end
end
