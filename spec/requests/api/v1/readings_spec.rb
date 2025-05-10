require 'rails_helper'

RSpec.describe "Api::V1::Readings", type: :request do
  let!(:challenge) { FactoryBot.create(:challenge) }

  describe "GET /api/v1/challenges/:challenge_id/readings" do
    let!(:readings) { FactoryBot.create_list(:reading, 3, challenge: challenge) }

    before { get "/api/v1/challenges/#{challenge.id}/readings" }

    it 'returns all readings for the challenge' do
      expect(json.size).to eq(3)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    context 'when challenge does not exist' do
      before { get "/api/v1/challenges/9999/readings" }
      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "POST /api/v1/challenges/:challenge_id/readings" do
    let(:valid_attributes) { { title: 'New Reading', scheduled_date: Date.today } }

    context 'with valid parameters' do
      it 'creates a new reading for the challenge' do
        expect {
          post "/api/v1/challenges/#{challenge.id}/readings", params: { reading: valid_attributes }
        }.to change(challenge.readings, :count).by(1)
      end

      it 'returns status code 201' do
        post "/api/v1/challenges/#{challenge.id}/readings", params: { reading: valid_attributes }
        expect(response).to have_http_status(201)
        expect(json['title']).to eq('New Reading')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a reading if title is missing' do
        expect {
          post "/api/v1/challenges/#{challenge.id}/readings", params: { reading: { scheduled_date: Date.today } }
        }.not_to change(Reading, :count)
        expect(response).to have_http_status(422)
        expect(json['errors']).to include("Title can't be blank")
      end
    end

    context 'when challenge does not exist' do
      it 'returns status code 404' do
        post "/api/v1/challenges/9999/readings", params: { reading: valid_attributes }
        expect(response).to have_http_status(404)
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
