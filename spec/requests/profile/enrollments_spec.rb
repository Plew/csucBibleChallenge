# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile::Enrollments', type: :request do
  let(:user) { create(:user) }

  let(:current_challenge) do
    create(:challenge,
      name: "Current Challenge",
      start_date: Date.current - 10.days,
      end_date: Date.current + 20.days,
      timezone: 'UTC')
  end

  let(:past_challenge) do
    create(:challenge,
      name: "Past Challenge",
      start_date: Date.current - 60.days,
      end_date: Date.current - 1.day,
      timezone: 'UTC')
  end

  let!(:current_enrollment) { create(:user_challenge_enrollment, user: user, challenge: current_challenge) }
  let!(:past_enrollment)    { create(:user_challenge_enrollment, user: user, challenge: past_challenge) }

  describe 'GET /profile/enrollments' do
    context 'when logged in' do
      before { login_via_session(user) }

      it 'returns success' do
        get profile_enrollments_path
        expect(response).to have_http_status(:success)
      end

      it 'shows current challenge name' do
        get profile_enrollments_path
        expect(response.body).to include("Current Challenge")
      end

      it 'shows past challenge name' do
        get profile_enrollments_path
        expect(response.body).to include("Past Challenge")
      end

      it 'shows current challenges section heading' do
        get profile_enrollments_path
        expect(response.body).to include(I18n.t('profile.current_challenges'))
      end

      it 'shows past challenges section heading' do
        get profile_enrollments_path
        expect(response.body).to include(I18n.t('profile.past_challenges'))
      end

      it 'links past challenge to archive show page' do
        get profile_enrollments_path
        expect(response.body).to include(profile_enrollment_path(past_enrollment))
      end

      context 'when user has no enrollments' do
        let(:user_no_challenges) { create(:user) }

        before { login_via_session(user_no_challenges) }

        it 'shows not enrolled message' do
          get profile_enrollments_path
          expect(response.body).to include(I18n.t('profile.not_enrolled'))
        end
      end
    end

    context 'when logged out' do
      it 'redirects to login' do
        get profile_enrollments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /profile/enrollments/:id (past challenge archive)' do
    context 'when logged in' do
      before { login_via_session(user) }

      context 'with a past challenge enrollment' do
        it 'returns success' do
          get profile_enrollment_path(past_enrollment)
          expect(response).to have_http_status(:success)
        end

        it 'shows the challenge name' do
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include("Past Challenge")
        end

        it 'shows the completion stat' do
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include(I18n.t('profile.archive.completion'))
        end

        it 'shows chapters read count' do
          reading = create(:reading, challenge: past_challenge, scheduled_date: past_challenge.start_date)
          create(:user_reading, user: user, reading: reading)
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include(I18n.t('profile.archive.chapters_read'))
        end

        it 'shows group name when user is in a group' do
          group = create(:group, challenge: past_challenge, creator: user)
          create(:user_group_enrollment, user: user, group: group)
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include(group.name)
        end

        it 'shows reading history section' do
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include(I18n.t('profile.archive.reading_history'))
        end

        it 'shows completed readings in the history table' do
          reading = create(:reading, challenge: past_challenge, scheduled_date: past_challenge.start_date, book_number: 1, chapter_number: 3)
          create(:user_reading, user: user, reading: reading)
          get profile_enrollment_path(past_enrollment)
          expect(response.body).to include("Genesis 3")
        end
      end

      context 'with a current (non-past) challenge enrollment' do
        it 'redirects to enrollments index' do
          get profile_enrollment_path(current_enrollment)
          expect(response).to redirect_to(profile_enrollments_path)
        end
      end

      context "when accessing another user's enrollment" do
        let(:other_user) { create(:user) }
        let!(:other_enrollment) { create(:user_challenge_enrollment, user: other_user, challenge: past_challenge) }

        it 'returns 404' do
          get profile_enrollment_path(other_enrollment)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when logged out' do
      it 'redirects to login' do
        get profile_enrollment_path(past_enrollment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
