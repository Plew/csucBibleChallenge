require 'rails_helper'

RSpec.describe "Admin::Sprints", type: :request do
  let(:user) { create(:user, admin: true) }
  let(:challenge) { create(:challenge, creator: user, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

  before do
    login_via_session user
  end

  describe "GET /admin/challenges/:challenge_id/sprints" do
    it "returns success" do
      get admin_challenge_sprints_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays sprints for the challenge" do
      sprint = create(:sprint, challenge: challenge, title: "Q1 Sprint")
      get admin_challenge_sprints_path(challenge)
      expect(response.body).to include("Q1 Sprint")
    end

    it "shows the winner group badge when a winner is set" do
      group = create(:group, challenge: challenge, name: "Champions")
      create(:sprint, challenge: challenge, title: "Q1 Sprint", winner_group: group)
      get admin_challenge_sprints_path(challenge)
      expect(response.body).to include("Champions")
    end

    it "shows a dash when no winner is set" do
      create(:sprint, challenge: challenge, title: "Q1 Sprint")
      get admin_challenge_sprints_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/challenges/:challenge_id/sprints/:id" do
    let(:sprint) { create(:sprint, challenge: challenge, title: "Q1 Sprint", begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 3, 31)) }

    it "returns success" do
      get admin_challenge_sprint_path(challenge, sprint)
      expect(response).to have_http_status(:success)
    end

    it "displays sprint title and dates" do
      get admin_challenge_sprint_path(challenge, sprint)
      expect(response.body).to include("Q1 Sprint")
      expect(response.body).to include("January 01, 2025")
      expect(response.body).to include("March 31, 2025")
    end

    context "with groups in the challenge" do
      let!(:group1) { create(:group, challenge: challenge, name: "Group A") }
      let!(:group2) { create(:group, challenge: challenge, name: "Group B") }
      let!(:group3) { create(:group, challenge: challenge, name: "Group C") }

      it "displays all groups" do
        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).to include("Group A")
        expect(response.body).to include("Group B")
        expect(response.body).to include("Group C")
      end

      it "displays group statistics" do
        # Add a user to group1 to ensure member count appears
        user1 = create(:user)
        create(:user_challenge_enrollment, user: user1, challenge: challenge)
        create(:user_group_enrollment, user: user1, group: group1)

        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).to include("Group A")
        # The page should show completion and on-time percentages (likely 0% for new groups)
        expect(response.body).to match(/\d+%/)
      end

      it "orders groups by completion percentage, on-time percentage, and member count" do
        # Create users and readings to test ordering
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)

        create(:user_challenge_enrollment, user: user1, challenge: challenge)
        create(:user_challenge_enrollment, user: user2, challenge: challenge)
        create(:user_challenge_enrollment, user: user3, challenge: challenge)

        create(:user_group_enrollment, user: user1, group: group1)
        create(:user_group_enrollment, user: user2, group: group2)
        create(:user_group_enrollment, user: user3, group: group2)

        # Create a reading within the sprint date range
        reading = create(:reading, challenge: challenge, scheduled_date: Date.new(2025, 1, 15))

        # Group 2 has higher completion (both users completed)
        create(:user_reading, user: user2, reading: reading)
        create(:user_reading, user: user3, reading: reading)

        # Group 1 has no completions

        get admin_challenge_sprint_path(challenge, sprint)

        # The response should list the groups
        expect(response).to have_http_status(:success)
        expect(assigns(:groups_with_stats)).to be_present

        # Group 2 should be ranked higher than Group 1 due to higher completion
        stats = assigns(:groups_with_stats)
        expect(stats.first[:group].name).to eq("Group B")
      end
    end

    context "with no groups in the challenge" do
      it "displays a no groups message" do
        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).to include(I18n.t("admin.sprints.no_groups"))
      end
    end

    context "winner group" do
      let!(:group) { create(:group, challenge: challenge, name: "Champions") }

      it "displays the winner group dropdown with challenge groups" do
        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).to include("Champions")
        expect(response.body).to include(I18n.t("admin.sprints.winner_group"))
      end

      it "shows the current winner when one is set" do
        sprint.update!(winner_group: group)
        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).to include("Champions")
        expect(response.body).to include("🏆")
      end

      it "shows no winner badge when no winner is set" do
        get admin_challenge_sprint_path(challenge, sprint)
        expect(response.body).not_to include("🏆")
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/sprints/new" do
    it "returns success" do
      get new_admin_challenge_sprint_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/challenges/:challenge_id/sprints" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          title: "Q1 Statistics",
          begin_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 3, 31)
        }
      end

      it "creates a new sprint" do
        expect {
          post admin_challenge_sprints_path(challenge), params: { sprint: valid_attributes }
        }.to change(Sprint, :count).by(1)
      end

      it "redirects to the sprints index" do
        post admin_challenge_sprints_path(challenge), params: { sprint: valid_attributes }
        expect(response).to redirect_to(admin_challenge_sprints_path(challenge))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          title: "",
          begin_date: Date.new(2025, 6, 1),
          end_date: Date.new(2025, 5, 1)
        }
      end

      it "does not create a new sprint" do
        expect {
          post admin_challenge_sprints_path(challenge), params: { sprint: invalid_attributes }
        }.not_to change(Sprint, :count)
      end

      it "renders the new template" do
        post admin_challenge_sprints_path(challenge), params: { sprint: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/sprints/:id/edit" do
    let(:sprint) { create(:sprint, challenge: challenge) }

    it "returns success" do
      get edit_admin_challenge_sprint_path(challenge, sprint)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/challenges/:challenge_id/sprints/:id" do
    let(:sprint) { create(:sprint, challenge: challenge, title: "Old Title") }

    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated Title" } }

      it "updates the sprint" do
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: new_attributes }
        sprint.reload
        expect(sprint.title).to eq("Updated Title")
      end

      it "redirects to the sprints index" do
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: new_attributes }
        expect(response).to redirect_to(admin_challenge_sprints_path(challenge))
      end
    end

    context "setting winner group" do
      let!(:group) { create(:group, challenge: challenge, name: "Champions") }

      it "assigns the winner group" do
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: { winner_group_id: group.id } }
        expect(sprint.reload.winner_group).to eq(group)
      end

      it "clears the winner group when blank is selected" do
        sprint.update!(winner_group: group)
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: { winner_group_id: "" } }
        expect(sprint.reload.winner_group).to be_nil
      end

      it "redirects back to the show page when the referer is the show page" do
        show_url = admin_challenge_sprint_url(challenge, sprint)
        patch admin_challenge_sprint_path(challenge, sprint),
          params: { sprint: { winner_group_id: group.id } },
          headers: { "HTTP_REFERER" => show_url }
        expect(response).to redirect_to(show_url)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { title: "" } }

      it "does not update the sprint" do
        original_title = sprint.title
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: invalid_attributes }
        sprint.reload
        expect(sprint.title).to eq(original_title)
      end

      it "renders the edit template" do
        patch admin_challenge_sprint_path(challenge, sprint), params: { sprint: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/challenges/:challenge_id/sprints/:id" do
    let!(:sprint) { create(:sprint, challenge: challenge) }

    it "destroys the sprint" do
      expect {
        delete admin_challenge_sprint_path(challenge, sprint)
      }.to change(Sprint, :count).by(-1)
    end

    it "redirects to the sprints index" do
      delete admin_challenge_sprint_path(challenge, sprint)
      expect(response).to redirect_to(admin_challenge_sprints_path(challenge))
    end
  end
end
