require 'rails_helper'

RSpec.describe UserReadingsController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, timezone: 'Berlin') }
  let(:today_reading) { create(:reading, challenge: challenge, scheduled_date: Time.current.in_time_zone('Berlin').to_date) }
  let(:future_reading) { create(:reading, challenge: challenge, scheduled_date: Time.current.in_time_zone('Berlin').to_date + 1.day) }

  before do
    session[:user_id] = user.id
  end

  describe 'POST #create' do
    context 'when attempting to mark a reading for today' do
      it 'creates a user reading successfully' do
        expect {
          post :create, params: { reading_id: today_reading.id }
        }.to change(UserReading, :count).by(1)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when attempting to mark a reading for a future date' do
      it 'prevents creating the user reading and shows an error' do
        expect {
          post :create, params: { reading_id: future_reading.id }
        }.not_to change(UserReading, :count)

        expect(flash[:alert]).to include('Cannot mark readings for future dates')
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
