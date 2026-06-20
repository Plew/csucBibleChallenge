require 'rails_helper'

RSpec.describe "Manage::Chapters", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  before { login_via_session(owner) }

  describe "GET /challenges/:challenge_id/manage/chapters" do
    it "returns success" do
      get challenge_manage_chapters_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "renders all readings with their scheduled dates and book/chapter" do
      create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 1), book_number: 1, chapter_number: 1)
      create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 2), book_number: 1, chapter_number: 2)
      create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 3), book_number: 2, chapter_number: 1)

      get challenge_manage_chapters_path(challenge)

      expect(response.body).to include("Jan 1, 2025")
      expect(response.body).to include("Jan 2, 2025")
      expect(response.body).to include("Jan 3, 2025")
      expect(response.body).to include("Genesis 1")
      expect(response.body).to include("Genesis 2")
      expect(response.body).to include("Exodus 1")
    end

    it "renders all readings for a challenge ordered by scheduled_date" do
      r3 = create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 3), book_number: 1, chapter_number: 3)
      r1 = create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 1), book_number: 1, chapter_number: 1)
      r2 = create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 2), book_number: 1, chapter_number: 2)

      get challenge_manage_chapters_path(challenge)

      body = response.body
      expect(body.index("Jan 1, 2025")).to be < body.index("Jan 2, 2025")
      expect(body.index("Jan 2, 2025")).to be < body.index("Jan 3, 2025")
    end

    it "shows no_chapters message when there are no readings" do
      get challenge_manage_chapters_path(challenge)
      expect(response.body).to include(I18n.t("manage.chapters.no_chapters"))
    end

    it "denies access to non-managers" do
      other_user = create(:user)
      login_via_session(other_user)
      get challenge_manage_chapters_path(challenge)
      expect(response).to redirect_to(root_path)
    end
  end
end
