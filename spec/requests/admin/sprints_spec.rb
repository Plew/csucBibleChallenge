require 'rails_helper'

RSpec.describe "Admin::Sprints", type: :request do
  let(:user) { create(:user, admin: true) }
  let(:challenge) { create(:challenge, creator: user, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

  before do
    login_as user
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
