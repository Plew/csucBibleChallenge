require 'rails_helper'

RSpec.describe "Verse Comments Toggle", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:reading) { create(:reading, challenge: challenge) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

  before { login_via_session(user) }

  describe "POST /readings/:reading_id/verse_messages" do
    context "when verse comments are enabled" do
      before { challenge.update!(verse_comments_enabled: true) }

      it "allows creating a comment" do
        post reading_verse_messages_path(reading), params: {
          verse_message: { content: "Test comment" },
          verse_number: 1
        }
        expect(response).not_to have_http_status(:forbidden)
        expect(VerseMessage.count).to eq(1)
      end
    end

    context "when verse comments are disabled" do
      before { challenge.update!(verse_comments_enabled: false) }

      it "returns forbidden" do
        post reading_verse_messages_path(reading), params: {
          verse_message: { content: "Test comment" },
          verse_number: 1
        }
        expect(response).to have_http_status(:forbidden)
        expect(VerseMessage.count).to eq(0)
      end
    end
  end
end
