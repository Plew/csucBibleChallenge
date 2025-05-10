require 'rails_helper'

# Helper method from other spec file, consider moving to spec_helper.rb
def json_response
  JSON.parse(response.body)
end

RSpec.describe "Api::V1::ChapterVerses", type: :request do
  describe "GET /api/v1/chapter_verses" do
    let!(:verse1) { FactoryBot.create(:verse, version: "KJV", book_number: 1, chapter_number: 1, verse_number: 1, verse_text: "In the beginning...") }
    let!(:verse2) { FactoryBot.create(:verse, version: "KJV", book_number: 1, chapter_number: 1, verse_number: 2, verse_text: "God created...") }
    let!(:verse_other_chapter) { FactoryBot.create(:verse, version: "KJV", book_number: 1, chapter_number: 2, verse_number: 1) }
    let!(:verse_other_book) { FactoryBot.create(:verse, version: "KJV", book_number: 2, chapter_number: 1, verse_number: 1) }
    let!(:verse_other_version) { FactoryBot.create(:verse, version: "ESV", book_number: 1, chapter_number: 1, verse_number: 1) }

    context "with valid parameters" do
      it "returns the verses for the specified chapter, ordered by verse_number" do
        get "/api/v1/chapter_verses", params: { version: "KJV", book_number: 1, chapter_number: 1 }
        
        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(2)
        expect(json_response.map { |v| v["id"] }).to eq([verse1.id, verse2.id])
        expect(json_response.first["verse_text"]).to eq("In the beginning...")
      end

      it "returns an empty array if no verses are found for the specified parameters" do
        get "/api/v1/chapter_verses", params: { version: "KJV", book_number: 1, chapter_number: 99 } # Assuming chapter 99 doesn't exist
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context "with missing parameters" do
      it "returns a bad_request if version is missing" do
        get "/api/v1/chapter_verses", params: { book_number: 1, chapter_number: 1 }
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include("Missing required parameters: version, book_number, and chapter_number must all be provided.")
      end

      it "returns a bad_request if book_number is missing" do
        get "/api/v1/chapter_verses", params: { version: "KJV", chapter_number: 1 }
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include("Missing required parameters: version, book_number, and chapter_number must all be provided.")
      end

      it "returns a bad_request if chapter_number is missing" do
        get "/api/v1/chapter_verses", params: { version: "KJV", book_number: 1 }
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include("Missing required parameters: version, book_number, and chapter_number must all be provided.")
      end
      
      it "returns a bad_request if all parameters are missing" do
        get "/api/v1/chapter_verses"
        expect(response).to have_http_status(:bad_request)
        expect(json_response["errors"]).to include("Missing required parameters: version, book_number, and chapter_number must all be provided.")
      end
    end

    # Optional: Test for non-integer book_number/chapter_number if strict type checking is added to controller
    # context "with non-integer book_number or chapter_number" do
    #   it "returns a bad_request if book_number is not an integer" do
    #     get "/api/v1/chapter_verses", params: { version: "KJV", book_number: "abc", chapter_number: 1 }
    #     expect(response).to have_http_status(:bad_request)
    #     expect(json_response["errors"]).to include("book_number and chapter_number must be integers.")
    #   end
    # end
  end
end 