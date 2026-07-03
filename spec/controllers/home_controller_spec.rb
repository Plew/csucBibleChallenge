require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe '#index' do
    context 'when user is not logged in' do
      it 'shows the welcome screen with challenges' do
        challenge = create(:challenge, end_date: 1.week.from_now)

        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:challenges)).to include(challenge)
      end
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }
      let(:challenge) { create(:challenge) }

      before do
        session[:user_id] = user.id
        create(:user_challenge_enrollment, user: user, challenge: challenge)
      end

      it 'redirects to reading path without date parameter' do
        get :index

        expect(response).to redirect_to(reading_path)
      end

      it 'redirects to reading path preserving date parameter' do
        target_date = '2025-09-15'

        get :index, params: { date: target_date }

        expect(response).to redirect_to(reading_path(date: target_date))
      end
    end
  end

  describe '#reading' do
    let(:user) { create(:user) }
    let(:challenge) { create(:challenge, timezone: 'UTC') }

    before do
      session[:user_id] = user.id
      create(:user_challenge_enrollment, user: user, challenge: challenge)
    end

    it 'uses today as default when no date parameter provided' do
      get :reading

      expect(response).to have_http_status(:success)
      expect(assigns(:selected_date)).to eq(Time.current.in_time_zone(challenge.timezone).to_date)
    end

    it 'uses provided date parameter when valid' do
      target_date = '2025-09-15'

      get :reading, params: { date: target_date }

      expect(response).to have_http_status(:success)
      expect(assigns(:selected_date)).to eq(Date.parse(target_date))
    end

    it 'falls back to today when invalid date parameter provided' do
      get :reading, params: { date: 'invalid-date' }

      expect(response).to have_http_status(:success)
      expect(assigns(:selected_date)).to eq(Time.current.in_time_zone(challenge.timezone).to_date)
    end

    describe 'banquet banner' do
      render_views

      it 'does not show the banner for users who have not qualified' do
        get :reading
        expect(assigns(:show_banquet_banner)).to be(false)
        expect(response.body).not_to include('celebration banquet')
      end

      it 'shows the banner once the user has finished Challenge #9 through the cutoff' do
        banquet_challenge = create(:challenge, id: User::BANQUET_CHALLENGE_ID, timezone: 'UTC')
        reading = create(:reading, challenge: banquet_challenge, scheduled_date: User::BANQUET_CUTOFF_DATE - 10.days)
        create(:user_reading, user: user, reading: reading)

        get :reading
        expect(assigns(:show_banquet_banner)).to be(true)
        expect(response.body).to include('celebration banquet')
      end
    end

    context 'when user has no challenges' do
      let(:user_without_challenges) { create(:user) }

      before do
        session[:user_id] = user_without_challenges.id
      end

      it 'redirects to challenges path' do
        available_challenge = create(:challenge, end_date: 1.week.from_now)

        get :reading

        expect(response).to redirect_to(challenges_path)
      end
    end
  end
end
