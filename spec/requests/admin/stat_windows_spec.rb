require 'rails_helper'

RSpec.describe "Admin::StatWindows", type: :request do
  let(:user) { create(:user, admin: true) }
  let(:challenge) { create(:challenge, creator: user, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 12, 31)) }

  before do
    login_as user
  end

  describe "GET /admin/challenges/:challenge_id/stat_windows" do
    it "returns success" do
      get admin_challenge_stat_windows_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays stat windows for the challenge" do
      stat_window = create(:stat_window, challenge: challenge, title: "Q1 Window")
      get admin_challenge_stat_windows_path(challenge)
      expect(response.body).to include("Q1 Window")
    end
  end

  describe "GET /admin/challenges/:challenge_id/stat_windows/new" do
    it "returns success" do
      get new_admin_challenge_stat_window_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/challenges/:challenge_id/stat_windows" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          title: "Q1 Statistics",
          begin_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 3, 31)
        }
      end

      it "creates a new stat window" do
        expect {
          post admin_challenge_stat_windows_path(challenge), params: { stat_window: valid_attributes }
        }.to change(StatWindow, :count).by(1)
      end

      it "redirects to the stat windows index" do
        post admin_challenge_stat_windows_path(challenge), params: { stat_window: valid_attributes }
        expect(response).to redirect_to(admin_challenge_stat_windows_path(challenge))
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

      it "does not create a new stat window" do
        expect {
          post admin_challenge_stat_windows_path(challenge), params: { stat_window: invalid_attributes }
        }.not_to change(StatWindow, :count)
      end

      it "renders the new template" do
        post admin_challenge_stat_windows_path(challenge), params: { stat_window: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/stat_windows/:id/edit" do
    let(:stat_window) { create(:stat_window, challenge: challenge) }

    it "returns success" do
      get edit_admin_challenge_stat_window_path(challenge, stat_window)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/challenges/:challenge_id/stat_windows/:id" do
    let(:stat_window) { create(:stat_window, challenge: challenge, title: "Old Title") }

    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated Title" } }

      it "updates the stat window" do
        patch admin_challenge_stat_window_path(challenge, stat_window), params: { stat_window: new_attributes }
        stat_window.reload
        expect(stat_window.title).to eq("Updated Title")
      end

      it "redirects to the stat windows index" do
        patch admin_challenge_stat_window_path(challenge, stat_window), params: { stat_window: new_attributes }
        expect(response).to redirect_to(admin_challenge_stat_windows_path(challenge))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { title: "" } }

      it "does not update the stat window" do
        original_title = stat_window.title
        patch admin_challenge_stat_window_path(challenge, stat_window), params: { stat_window: invalid_attributes }
        stat_window.reload
        expect(stat_window.title).to eq(original_title)
      end

      it "renders the edit template" do
        patch admin_challenge_stat_window_path(challenge, stat_window), params: { stat_window: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/challenges/:challenge_id/stat_windows/:id" do
    let!(:stat_window) { create(:stat_window, challenge: challenge) }

    it "destroys the stat window" do
      expect {
        delete admin_challenge_stat_window_path(challenge, stat_window)
      }.to change(StatWindow, :count).by(-1)
    end

    it "redirects to the stat windows index" do
      delete admin_challenge_stat_window_path(challenge, stat_window)
      expect(response).to redirect_to(admin_challenge_stat_windows_path(challenge))
    end
  end
end
