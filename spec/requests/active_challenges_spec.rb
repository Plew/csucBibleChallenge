# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Active Challenges & Multi-Challenge Navigation", type: :request do
  let(:user) { create(:user) }
  let(:today) { Date.current }

  let!(:challenge1) do
    create(:challenge,
           name: "Challenge One (Gospels)",
           start_date: today - 5.days,
           end_date: today + 25.days)
  end

  let!(:challenge2) do
    create(:challenge,
           name: "Challenge Two (Epistles)",
           start_date: today - 2.days,
           end_date: today + 28.days)
  end

  let!(:reading1) do
    create(:reading, challenge: challenge1, book_number: 40, chapter_number: 1, scheduled_date: today)
  end

  let!(:reading2) do
    create(:reading, challenge: challenge2, book_number: 45, chapter_number: 1, scheduled_date: today)
  end

  let!(:group1) { create(:group, challenge: challenge1, name: "Team Alpha") }
  let!(:group2) { create(:group, challenge: challenge2, name: "Team Beta") }

  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  before do
    create(:user_challenge_enrollment, user: user, challenge: challenge1, created_at: 2.days.ago)
    create(:user_challenge_enrollment, user: user, challenge: challenge2, created_at: 1.day.ago)
    create(:user_group_enrollment, user: user, group: group1)
    create(:user_group_enrollment, user: user, group: group2)
    log_in_as(user)
  end

  describe "Multi-challenge enrollment" do
    let(:new_challenge) { create(:challenge, name: "Challenge Three") }

    it "allows enrolling in an additional challenge when already enrolled in others" do
      expect do
        post challenge_enrollments_path(new_challenge)
      end.to change(user.user_challenge_enrollments, :count).by(1)

      expect(user.challenges).to include(new_challenge)
    end
  end

  describe "PATCH /active_challenge" do
    it "switches the active challenge in session and redirects" do
      patch switch_active_challenge_path, params: { challenge_id: challenge1.id, redirect_to: reading_path }

      expect(response).to redirect_to(reading_path)
      follow_redirect!
      expect(response.body).to include(challenge1.name)
    end

    it "switches active challenge and responds with Turbo Stream when requested" do
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("main_nav_bar")
      expect(response.body).to include("flash_messages")
      expect(response.body).to include(challenge2.name)
    end
  end

  describe "Navbar 4th element & Switcher" do
    it "renders the bottom navbar with Reading, Group, Stats, and Challenges elements" do
      get reading_path

      expect(response.body).to include(I18n.t("navigation.reading"))
      expect(response.body).to include(I18n.t("navigation.group"))
      expect(response.body).to include(I18n.t("navigation.stats"))
      expect(response.body).to include(I18n.t("navigation.challenges"))
    end

    it "includes both enrolled challenges and read status in the switcher dropdown" do
      create(:user_reading, user: user, reading: reading1, completed_on: today)

      get reading_path

      expect(response.body).to include("challenge-switcher-dropdown")
      expect(response.body).to include(challenge1.name)
      expect(response.body).to include(challenge2.name)
      expect(response.body).to include("Read today")
      expect(response.body).to include("Unread today")
    end
  end

  describe "Scoping pages to active challenge" do
    it "scopes reading page to the active challenge" do
      # Switch to challenge1
      patch switch_active_challenge_path, params: { challenge_id: challenge1.id }

      get reading_path
      expect(response.body).to include(reading1.chapter_number.to_s)

      # Switch to challenge2
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }

      get reading_path
      expect(response.body).to include(reading2.chapter_number.to_s)
    end

    it "scopes groups page to the active challenge" do
      # Switch to challenge1
      patch switch_active_challenge_path, params: { challenge_id: challenge1.id }

      get groups_path
      expect(response).to redirect_to(group_path(group1))

      # Switch to challenge2
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }

      get groups_path
      expect(response).to redirect_to(group_path(group2))
    end

    it "scopes stats page to the active challenge" do
      patch switch_active_challenge_path, params: { challenge_id: challenge1.id }
      get "/stats"
      expect(response).to have_http_status(:success)

      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }
      get "/stats"
      expect(response).to have_http_status(:success)
    end

    it "safely redirects to the new challenge group when switching from a group detail page" do
      # User is on group1 (which belongs to challenge1) and switches to challenge2
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id, redirect_to: group_path(group1) }
      expect(response).to redirect_to(groups_path)
      follow_redirect!
      expect(response).to redirect_to(group_path(group2))
    end

    it "safely redirects to catch_up, posts, and seven_day_win when switching on those pages" do
      # Catch up
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id, redirect_to: challenge_catch_up_path(challenge1) }
      expect(response).to redirect_to(catch_up_path)

      # Posts
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id, redirect_to: challenge_blog_posts_path(challenge1) }
      expect(response).to redirect_to(posts_path)

      # Seven Day Win
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id, redirect_to: challenge_seven_day_lobby_path(challenge1) }
      expect(response).to redirect_to(seven_day_win_path)
    end

    it "safely redirects to the corresponding manage section if user manages the new challenge" do
      challenge1.update!(creator: user)
      challenge2.update!(creator: user)

      patch switch_active_challenge_path, params: { challenge_id: challenge2.id, redirect_to: challenge_manage_settings_path(challenge1) }
      expect(response).to redirect_to("/challenges/#{challenge2.id}/manage/settings")
    end

    it "handles direct navigation to a foreign group ID by redirecting to groups_path" do
      # Set active challenge to challenge2
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }
      # Request group1 (belongs to challenge1)
      get group_path(group1)
      expect(response).to redirect_to(groups_path)
    end
  end

  describe "GET /challenges/hub" do
    it "displays all enrolled challenges and the active challenge highlight" do
      get challenges_hub_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(challenge1.name)
      expect(response.body).to include(challenge2.name)
    end
  end
end
