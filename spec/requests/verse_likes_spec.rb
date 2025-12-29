require 'rails_helper'

RSpec.describe "VerseLikes", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 1) }

  describe "POST /readings/:reading_id/verse_like" do
    context "when user is logged in" do
      before { login_via_session(user) }

      context "when user has not liked the verse" do
        it "creates a new like" do
          expect {
            post reading_toggle_verse_like_path(reading, verse_number: 1)
          }.to change(VerseLike, :count).by(1)
        end

        it "associates the like with the current user" do
          post reading_toggle_verse_like_path(reading, verse_number: 1)
          expect(VerseLike.last.user).to eq(user)
        end

        it "associates the like with the correct reading and verse" do
          post reading_toggle_verse_like_path(reading, verse_number: 5)
          like = VerseLike.last
          expect(like.reading).to eq(reading)
          expect(like.verse_number).to eq(5)
        end

        it "responds with turbo_stream when requested" do
          post reading_toggle_verse_like_path(reading, verse_number: 1),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "redirects back for HTML requests" do
          post reading_toggle_verse_like_path(reading, verse_number: 1),
               headers: { "HTTP_REFERER" => reading_path }
          expect(response).to redirect_to(reading_path)
        end
      end

      context "when user has already liked the verse" do
        let!(:existing_like) { create(:verse_like, user: user, reading: reading, verse_number: 1) }

        it "removes the existing like" do
          expect {
            post reading_toggle_verse_like_path(reading, verse_number: 1)
          }.to change(VerseLike, :count).by(-1)
        end

        it "destroys the correct like" do
          post reading_toggle_verse_like_path(reading, verse_number: 1)
          expect(VerseLike.exists?(existing_like.id)).to be false
        end
      end

      context "with multiple users liking the same verse" do
        let!(:other_like) { create(:verse_like, user: other_user, reading: reading, verse_number: 1) }

        it "only affects the current user's like" do
          # First, create user's like
          post reading_toggle_verse_like_path(reading, verse_number: 1)
          expect(VerseLike.count).to eq(2)

          # Toggle off user's like
          post reading_toggle_verse_like_path(reading, verse_number: 1)
          expect(VerseLike.count).to eq(1)
          expect(VerseLike.first).to eq(other_like)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        post reading_toggle_verse_like_path(reading, verse_number: 1)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a like" do
        expect {
          post reading_toggle_verse_like_path(reading, verse_number: 1)
        }.not_to change(VerseLike, :count)
      end
    end
  end

  describe "like count in response" do
    before { login_via_session(user) }

    it "includes updated like count in turbo_stream response" do
      # Create some existing likes from other users
      create(:verse_like, user: other_user, reading: reading, verse_number: 1)

      post reading_toggle_verse_like_path(reading, verse_number: 1),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # After adding user's like, count should be 2
      expect(response.body).to include("2")
    end
  end
end
