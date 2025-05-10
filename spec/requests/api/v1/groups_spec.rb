require 'rails_helper'

RSpec.describe "Api::V1::Groups", type: :request do
  let!(:challenge) { FactoryBot.create(:challenge) }

  describe "GET /api/v1/challenges/:challenge_id/groups" do
    let!(:groups) { FactoryBot.create_list(:group, 2, challenge: challenge) }
    before { get "/api/v1/challenges/#{challenge.id}/groups" }

    it 'returns all groups for the challenge' do
      expect(json.size).to eq(2)
      expect(json[0]['name']).to eq(groups.first.name)
    end
    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /api/v1/challenges/:challenge_id/groups" do
    let(:valid_attributes) { { name: 'New Group' } }

    context 'with valid parameters' do
      it 'creates a new group for the challenge' do
        expect {
          post "/api/v1/challenges/#{challenge.id}/groups", params: { group: valid_attributes }
        }.to change(challenge.groups, :count).by(1)
      end
      it 'returns status code 201' do
        post "/api/v1/challenges/#{challenge.id}/groups", params: { group: valid_attributes }
        expect(response).to have_http_status(201)
        expect(json['name']).to eq('New Group')
      end
    end

    context 'with invalid parameters (e.g., duplicate name for same challenge)' do
      before { FactoryBot.create(:group, name: 'Existing Group', challenge: challenge) }
      it 'does not create a group if name is duplicate for the challenge' do
        expect {
          post "/api/v1/challenges/#{challenge.id}/groups", params: { group: { name: 'Existing Group' } }
        }.not_to change(Group, :count)
        expect(response).to have_http_status(422)
        expect(json['errors']).to include("Name name should be unique within the challenge")
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
