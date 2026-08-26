require 'rails_helper'

RSpec.describe UserReadingsController, type: :controller do
  # Freeze time to 2024-06-15 12:00 UTC.
  # Worldwide window: Jun 14 (UTC-12) to Jun 16 (UTC+14)
  around do |example|
    travel_to(Time.utc(2024, 6, 15, 12, 0, 0)) { example.run }
  end

  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, start_date: Date.new(2024, 6, 1), end_date: Date.new(2024, 6, 30), timezone: 'Berlin') }

  before do
    session[:user_id] = user.id
    create(:user_challenge_enrollment, user: user, challenge: challenge)
  end

  describe 'POST #create' do
    context 'when scheduled_date is today in UTC (within worldwide window)' do
      let(:reading) { create(:reading, challenge: challenge, book_number: 40, chapter_number: 1, scheduled_date: Date.new(2024, 6, 15)) }

      it 'creates a user reading with completed_on = scheduled_date' do
        expect {
          post :create, params: { reading_id: reading.id }
        }.to change(UserReading, :count).by(1)

        expect(UserReading.last.completed_on).to eq(Date.new(2024, 6, 15))
        expect(response).to redirect_to(reading_path)
      end
    end

    context 'when scheduled_date is tomorrow UTC (UTC+14 case, within worldwide window)' do
      let(:reading) { create(:reading, challenge: challenge, book_number: 40, chapter_number: 2, scheduled_date: Date.new(2024, 6, 16)) }

      it 'creates a user reading with completed_on = scheduled_date' do
        expect {
          post :create, params: { reading_id: reading.id }
        }.to change(UserReading, :count).by(1)

        expect(UserReading.last.completed_on).to eq(Date.new(2024, 6, 16))
        expect(response).to redirect_to(reading_path)
      end
    end

    context 'when scheduled_date is truly future (beyond worldwide window)' do
      let(:reading) { create(:reading, challenge: challenge, book_number: 40, chapter_number: 3, scheduled_date: Date.new(2024, 6, 17)) }

      it 'rejects the request with a future date error' do
        expect {
          post :create, params: { reading_id: reading.id }
        }.not_to change(UserReading, :count)

        expect(flash[:alert]).to include('Cannot mark readings for future dates')
        expect(response).to redirect_to(reading_path)
      end
    end

    context 'when scheduled_date is in the past (late completion)' do
      let(:reading) { create(:reading, challenge: challenge, book_number: 40, chapter_number: 4, scheduled_date: Date.new(2024, 6, 14)) }

      it 'creates a user reading with completed_on = current date in challenge timezone' do
        expect {
          post :create, params: { reading_id: reading.id }
        }.to change(UserReading, :count).by(1)

        expected_date = Time.current.in_time_zone('Berlin').to_date
        expect(UserReading.last.completed_on).to eq(expected_date)
        expect(response).to redirect_to(reading_path)
      end
    end
  end
end
