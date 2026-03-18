require 'rails_helper'

RSpec.describe "Challenge Index Page", type: :request do
  let!(:challenge) do
    create(:challenge, hidden: false, start_date: Date.current, end_date: Date.current + 30.days)
  end
  let!(:reading) { create(:reading, challenge: challenge, book_number: 1, chapter_number: 1, scheduled_date: challenge.start_date) }
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:enrollment1) { create(:user_challenge_enrollment, user: user1, challenge: challenge) }
  let!(:enrollment2) { create(:user_challenge_enrollment, user: user2, challenge: challenge) }
  let!(:group) { create(:group, challenge: challenge, creator: user1) }

  describe "GET /challenges" do
    it "shows participant count" do
      get challenges_path
      expect(response.body).to include("2")
    end

    it "shows group count" do
      get challenges_path
      expect(response.body).to include(I18n.t("navigation.groups"))
    end

    it "shows start and end dates" do
      get challenges_path
      expect(response.body).to include(challenge.start_date.strftime('%-d %b %Y'))
      expect(response.body).to include(challenge.end_date.strftime('%-d %b %Y'))
    end

    it "shows Details button text instead of Join Challenge" do
      get challenges_path
      expect(response.body).to include(I18n.t("challenges.details"))
      expect(response.body).not_to include("Join Challenge")
    end

    it "shows reading range" do
      get challenges_path
      expect(response.body).to include("Genesis")
    end

    context "Create Challenge button" do
      it "is visible for users not enrolled in any challenge" do
        user = create(:user)
        login_via_session(user)
        get challenges_path
        expect(response.body).to include(I18n.t("challenges.create_new"))
      end

      it "is not visible for users already enrolled in a challenge" do
        enrolled_user = create(:user)
        create(:user_challenge_enrollment, user: enrolled_user, challenge: challenge)
        login_via_session(enrolled_user)
        get challenges_path
        expect(response.body).not_to include(I18n.t("challenges.create_new"))
      end
    end
  end
end
