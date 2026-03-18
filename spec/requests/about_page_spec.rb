require 'rails_helper'

RSpec.describe "About Page", type: :request do
  describe "GET /about" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end

    it "contains section headings" do
      get about_path
      expect(response.body).to include(I18n.t("about.title"))
      expect(response.body).to include(I18n.t("about.what_is_title"))
      expect(response.body).to include(I18n.t("about.how_it_works_title"))
      expect(response.body).to include(I18n.t("about.groups_title"))
      expect(response.body).to include(I18n.t("about.statistics_title"))
      expect(response.body).to include(I18n.t("about.sprints_title"))
      expect(response.body).to include(I18n.t("about.seven_day_win_title"))
    end

    it "is accessible without login" do
      get about_path
      expect(response).not_to redirect_to(new_user_session_path)
    end

    it "has About link in the menu for logged-out users" do
      get about_path
      expect(response.body).to include(I18n.t("navigation.about"))
    end

    it "has About link in the menu for logged-in users" do
      user = create(:user)
      login_via_session(user)
      get about_path
      expect(response.body).to include(about_path)
    end
  end
end
