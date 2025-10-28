require 'rails_helper'

RSpec.describe VerseLikesController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:reading) { create(:reading, challenge: challenge) }

  before do
    session[:user_id] = user.id
  end

  describe 'POST #create' do
    context 'when liking a verse for the first time' do
      it 'creates a verse like successfully' do
        expect {
          post :create, params: { reading_id: reading.id, verse_number: 1 }, format: :json
        }.to change(VerseLike, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be true
        expect(json_response['like_count']).to eq(1)
      end
    end

    context 'when liking an already liked verse' do
      before do
        create(:verse_like, user: user, reading: reading, verse_number: 1)
      end

      it 'does not create a duplicate like' do
        expect {
          post :create, params: { reading_id: reading.id, verse_number: 1 }, format: :json
        }.not_to change(VerseLike, :count)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be true
        expect(json_response['like_count']).to eq(1)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when unliking a liked verse' do
      before do
        create(:verse_like, user: user, reading: reading, verse_number: 1)
      end

      it 'removes the like successfully' do
        expect {
          delete :destroy, params: { reading_id: reading.id, id: 1, verse_number: 1 }, format: :json
        }.to change(VerseLike, :count).by(-1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be false
        expect(json_response['like_count']).to eq(0)
      end
    end

    context 'when unliking a verse that is not liked' do
      it 'returns success with like_count 0' do
        expect {
          delete :destroy, params: { reading_id: reading.id, id: 1, verse_number: 1 }, format: :json
        }.not_to change(VerseLike, :count)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['liked']).to be false
        expect(json_response['like_count']).to eq(0)
      end
    end
  end

  describe 'multiple users liking the same verse' do
    let(:user2) { create(:user) }

    before do
      create(:verse_like, user: user, reading: reading, verse_number: 1)
    end

    it 'tracks likes from different users' do
      session[:user_id] = user2.id

      expect {
        post :create, params: { reading_id: reading.id, verse_number: 1 }, format: :json
      }.to change(VerseLike, :count).by(1)

      json_response = JSON.parse(response.body)
      expect(json_response['like_count']).to eq(2)
    end
  end
end
