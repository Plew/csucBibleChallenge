require 'rails_helper'

RSpec.describe "Navigation Menu", type: :request do
  def log_in_as(user)
    post user_session_path, params: { session: { email: user.email, password: "password123" } }
  end

  def build_creator
    # Non-admin user who can create challenges
    create(:user, can_create_challenges: true)
  end

  describe "Admin link visibility" do
    context "when user is an admin" do
      let(:admin_user) { create(:user, :admin) }

      before do
        log_in_as(admin_user)
        follow_redirect!
      end

      it "shows the Admin link pointing to admin root" do
        expect(response.body).to include(I18n.t("navigation.admin"))
        expect(response.body).to include(admin_root_path)
      end

      it "does not show Manage Feedback separately" do
        expect(response.body).not_to include(I18n.t("navigation.manage_feedback"))
      end
    end

    context "when user is a regular user" do
      let(:regular_user) { create(:user) }

      before do
        log_in_as(regular_user)
        follow_redirect!
      end

      it "does not show the Admin link in the menu" do
        expect(response.body).not_to include(">" + I18n.t("navigation.admin") + "</a>")
      end
    end

    context "when user is not logged in" do
      it "does not show the Admin link" do
        get root_path
        expect(response.body).not_to include(">" + I18n.t("navigation.admin") + "</a>")
      end
    end
  end

  describe "Manage challenge link" do
    context "when user manages a single challenge" do
      let(:creator) { build_creator }
      let!(:challenge) { create(:challenge, creator: creator) }

      before do
        log_in_as(creator)
        get about_path
      end

      it "shows Manage challenge link from a non-challenge page" do
        expect(response.body).to include(I18n.t("navigation.manage_challenge"))
      end

      it "links directly to the manage console (no chooser needed)" do
        expect(response.body).to include(challenge_manage_dashboard_path(challenge))
      end

      it "does not link to the chooser" do
        # manage_chooser_path is "/manage"; check it doesn't appear as an exact href
        expect(response.body).not_to match(%r{href="/manage"})
      end
    end

    context "when user manages multiple challenges" do
      let(:creator) { build_creator }
      let!(:challenge1) { create(:challenge, name: "Challenge One", creator: creator) }
      let!(:challenge2) { create(:challenge, name: "Challenge Two", creator: creator) }

      before do
        create(:user_challenge_enrollment, user: creator, challenge: challenge1)
        create(:user_challenge_enrollment, user: creator, challenge: challenge2)
        log_in_as(creator)
      end

      it "links Manage challenge to the currently active challenge" do
        patch switch_active_challenge_path, params: { challenge_id: challenge1.id }
        get about_path
        expect(response.body).to include(challenge_manage_dashboard_path(challenge1))

        patch switch_active_challenge_path, params: { challenge_id: challenge2.id }
        get about_path
        expect(response.body).to include(challenge_manage_dashboard_path(challenge2))
      end

      it "links Catch Up, Posts, and Weekly Winner to the currently active challenge" do
        patch switch_active_challenge_path, params: { challenge_id: challenge2.id }
        get about_path
        expect(response.body).to include(challenge_catch_up_path(challenge2))
        expect(response.body).to include(challenge_blog_posts_path(challenge2))
        expect(response.body).to include(challenge_seven_day_lobby_path(challenge2))
      end
    end

    context "when user is an organizer of a challenge" do
      let(:organizer) { create(:user) }
      let!(:challenge) { create(:challenge) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: organizer, challenge: challenge, role: "organizer") }

      before do
        log_in_as(organizer)
        get about_path
      end

      it "shows Manage challenge link" do
        expect(response.body).to include(I18n.t("navigation.manage_challenge"))
      end

      it "links directly to the active challenge console" do
        expect(response.body).to include(challenge_manage_dashboard_path(challenge))
      end
    end

    context "when user owns no challenges and has no organizer role" do
      let(:user) { create(:user) }
      let!(:challenge) { create(:challenge) }
      let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

      before do
        log_in_as(user)
        get about_path
      end

      it "does not show Manage challenge link" do
        expect(response.body).not_to include(I18n.t("navigation.manage_challenge"))
      end
    end

    context "when user is a site admin with no owned challenges" do
      let(:admin_user) { create(:user, :admin) }

      before do
        log_in_as(admin_user)
        follow_redirect!
      end

      it "shows Admin link" do
        expect(response.body).to include(I18n.t("navigation.admin"))
      end

      it "does not show Manage challenge link" do
        expect(response.body).not_to include(I18n.t("navigation.manage_challenge"))
      end
    end
  end

  describe "Manage challenge reachability from non-challenge pages" do
    let(:creator) { build_creator }
    let!(:challenge) { create(:challenge, creator: creator) }

    before { log_in_as(creator) }

    it "is reachable from the about page (no @challenge set)" do
      get about_path
      expect(response.body).to include(I18n.t("navigation.manage_challenge"))
      expect(response.body).to include(challenge_manage_dashboard_path(challenge))
    end

    it "is reachable from the account settings page" do
      get account_path
      expect(response.body).to include(I18n.t("navigation.manage_challenge"))
      expect(response.body).to include(challenge_manage_dashboard_path(challenge))
    end
  end

  describe "challenge_admin label is gone from nav" do
    context "when user owns a challenge" do
      let(:creator) { build_creator }
      let!(:challenge) { create(:challenge, creator: creator) }

      before do
        log_in_as(creator)
        get challenge_path(challenge)
      end

      it "does not show the old challenge_admin label" do
        expect(response.body).not_to include(I18n.t("navigation.challenge_admin"))
      end

      it "shows the unified manage_challenge label instead" do
        expect(response.body).to include(I18n.t("navigation.manage_challenge"))
      end
    end
  end

  describe "Manage chooser page" do
    let(:creator) { build_creator }
    let!(:challenge1) { create(:challenge, name: "Alpha Challenge", creator: creator) }
    let!(:challenge2) { create(:challenge, name: "Beta Challenge", creator: creator) }

    before do
      create(:user_challenge_enrollment, user: creator, challenge: challenge1)
      create(:user_challenge_enrollment, user: creator, challenge: challenge2)
      log_in_as(creator)
    end

    it "redirects directly to active challenge dashboard if active challenge is managed" do
      patch switch_active_challenge_path, params: { challenge_id: challenge2.id }
      get manage_chooser_path
      expect(response).to redirect_to(challenge_manage_dashboard_path(challenge2))
    end

    it "lists all managed challenges when active challenge is not managed" do
      unmanaged = create(:challenge)
      create(:user_challenge_enrollment, user: creator, challenge: unmanaged)
      patch switch_active_challenge_path, params: { challenge_id: unmanaged.id }

      get manage_chooser_path
      expect(response.body).to include("Alpha Challenge")
      expect(response.body).to include("Beta Challenge")
    end

    it "redirects directly when only one challenge is managed" do
      challenge2.update!(creator: create(:user, :admin))
      creator.user_challenge_enrollments.where(challenge: challenge2).destroy_all
      get manage_chooser_path
      expect(response).to redirect_to(challenge_manage_dashboard_path(challenge1))
    end

    it "requires login" do
      delete destroy_user_session_path
      get manage_chooser_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "Bottom navigation bar" do
    let(:user) { create(:user) }
    let!(:challenge1) { create(:challenge, name: "Challenge One") }
    let!(:challenge2) { create(:challenge, name: "Challenge Two") }

    before do
      create(:user_challenge_enrollment, user: user, challenge: challenge1)
      create(:user_challenge_enrollment, user: user, challenge: challenge2)
      log_in_as(user)
    end

    it "renders all 4 items: Reading, Group, Stats, Challenges" do
      get reading_path
      expect(response.body).to include(I18n.t("navigation.reading"))
      expect(response.body).to include(I18n.t("navigation.group"))
      expect(response.body).to include(I18n.t("navigation.stats"))
      expect(response.body).to include(I18n.t("navigation.challenges"))
    end

    it "includes the challenge switcher dropdown with enrolled challenges" do
      get reading_path
      expect(response.body).to include("challenge-switcher-dropdown")
      expect(response.body).to include("Challenge One")
      expect(response.body).to include("Challenge Two")
    end
  end
end
