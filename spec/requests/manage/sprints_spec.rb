require 'rails_helper'

RSpec.describe "Manage::Sprints", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

  before { login_via_session(owner) }

  describe "GET /challenges/:challenge_id/manage/sprints" do
    it "returns success" do
      get challenge_manage_sprints_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays sprints" do
      create(:sprint, challenge: challenge, title: "Q1 Sprint")
      get challenge_manage_sprints_path(challenge)
      expect(response.body).to include("Q1 Sprint")
    end
  end

  describe "GET /challenges/:challenge_id/manage/sprints/new" do
    it "returns success" do
      get new_challenge_manage_sprint_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /challenges/:challenge_id/manage/sprints" do
    let(:valid_attributes) do
      { title: "Q1 Stats", begin_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 3, 31) }
    end

    it "creates a new sprint" do
      expect {
        post challenge_manage_sprints_path(challenge), params: { sprint: valid_attributes }
      }.to change(Sprint, :count).by(1)
    end

    it "redirects to index" do
      post challenge_manage_sprints_path(challenge), params: { sprint: valid_attributes }
      expect(response).to redirect_to(challenge_manage_sprints_path(challenge))
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/sprints/:id" do
    let(:sprint) { create(:sprint, challenge: challenge, title: "Old") }

    it "updates the sprint" do
      patch challenge_manage_sprint_path(challenge, sprint), params: { sprint: { title: "New" } }
      sprint.reload
      expect(sprint.title).to eq("New")
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/sprints/:id" do
    let!(:sprint) { create(:sprint, challenge: challenge) }

    it "destroys the sprint" do
      expect {
        delete challenge_manage_sprint_path(challenge, sprint)
      }.to change(Sprint, :count).by(-1)
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { create(:user) }
    before { login_via_session(other_user) }

    it "denies access" do
      get challenge_manage_sprints_path(challenge)
      expect(response).to redirect_to(root_path)
    end
  end
end
