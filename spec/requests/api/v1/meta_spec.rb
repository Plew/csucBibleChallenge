require "rails_helper"

RSpec.describe "Api::V1::Meta", type: :request do
  let(:challenge) { create(:challenge) }

  def auth_header(key)
    { "Authorization" => "Bearer #{key}" }
  end

  describe "GET /api/v1/meta" do
    it "returns 401 without a key" do
      get api_v1_meta_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid key" do
      get api_v1_meta_path, headers: auth_header("csmbc_not_real")
      expect(response).to have_http_status(:unauthorized)
    end

    context "with a valid key" do
      before { challenge.regenerate_api_key! }

      it "returns the self-description scoped to the key's challenge" do
        get api_v1_meta_path, headers: auth_header(challenge.api_key)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body.dig("challenge", "id")).to eq(challenge.id)
        expect(body).to include("auth", "endpoints", "field_glossary", "example_report_shape")
        paths = body["endpoints"].map { |e| e["path"] }
        expect(paths).to include("/api/v1/challenges/#{challenge.id}/report")
      end
    end
  end
end
