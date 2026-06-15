# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CatchUp', type: :request do
  let(:challenge) { create(:challenge, timezone: 'UTC', start_date: Date.current - 30.days) }
  let(:user) { create(:user) }

  before { create(:user_challenge_enrollment, user: user, challenge: challenge) }

  # Three past-due readings, today's reading, and a future reading.
  let!(:missed_old)  { create(:reading, challenge: challenge, scheduled_date: Date.current - 3.days, book_number: 1, chapter_number: 5) }
  let!(:missed_new)  { create(:reading, challenge: challenge, scheduled_date: Date.current - 1.day,  book_number: 1, chapter_number: 7) }
  let!(:today_read)  { create(:reading, challenge: challenge, scheduled_date: Date.current,           book_number: 1, chapter_number: 8) }
  let!(:future_read) { create(:reading, challenge: challenge, scheduled_date: Date.current + 1.day,   book_number: 1, chapter_number: 9) }

  describe 'GET /challenges/:challenge_id/catch_up' do
    context 'when logged in and enrolled' do
      before { login_via_session(user) }

      it 'returns success' do
        get challenge_catch_up_path(challenge)
        expect(response).to have_http_status(:success)
      end

      it 'counts only past-due unread readings (excludes today and future)' do
        get challenge_catch_up_path(challenge)
        expect(response.body).to include(I18n.t('catch_up.heading', count: 2))
      end

      it 'excludes readings the user has already completed' do
        create(:user_reading, user: user, reading: missed_old)
        get challenge_catch_up_path(challenge)
        expect(response.body).to include(I18n.t('catch_up.heading', count: 1))
      end

      it 'lists missed readings oldest first with links to the reading page' do
        get challenge_catch_up_path(challenge)
        expect(response.body).to include(reading_path(date: missed_old.scheduled_date))
        expect(response.body).to include(reading_path(date: missed_new.scheduled_date))
        # oldest (Genesis 5) appears before newest (Genesis 7)
        expect(response.body.index('Genesis 5')).to be < response.body.index('Genesis 7')
      end

      it 'shows the celebratory empty state when nothing is missed' do
        [ missed_old, missed_new ].each { |r| create(:user_reading, user: user, reading: r) }
        get challenge_catch_up_path(challenge)
        expect(response.body).to include(CGI.escapeHTML(I18n.t('catch_up.all_caught_up')))
      end
    end

    context 'when logged in but not enrolled' do
      let(:outsider) { create(:user) }

      before { login_via_session(outsider) }

      it 'redirects to the challenges list' do
        get challenge_catch_up_path(challenge)
        expect(response).to redirect_to(challenges_path)
      end
    end

    context 'when logged out' do
      it 'redirects to the sign-in page' do
        get challenge_catch_up_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
