require 'rails_helper'

RSpec.describe "Api::V1::Challenges", type: :request do
  let!(:challenges) { FactoryBot.create_list(:challenge, 3) }
  let(:challenge_id) { challenges.first.id }

  describe "GET /api/v1/challenges" do
    before { get '/api/v1/challenges' }

    it 'returns challenges' do
      expect(json).not_to be_empty
      expect(json.size).to eq(3)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /api/v1/challenges/:id" do
    before { get "/api/v1/challenges/#{challenge_id}" }

    context 'when the record exists' do
      it 'returns the challenge' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(challenge_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:challenge_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Challenge not found/)
      end
    end
  end

  describe "POST /api/v1/challenges" do
    let(:valid_attributes) { { name: 'New Challenge', start_date: Date.today, end_date: Date.today + 7.days } }

    context 'with valid parameters' do
      before { post '/api/v1/challenges', params: { challenge: valid_attributes } }

      it 'creates a new challenge' do
        expect(json['name']).to eq('New Challenge')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'with invalid parameters' do
      before { post '/api/v1/challenges', params: { challenge: { name: '' } } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(json['errors']).to include("Name can't be blank")
      end
    end
  end

  # Helper method to parse JSON responses
  def json
    JSON.parse(response.body)
  end
end
