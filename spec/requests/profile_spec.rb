require "rails_helper"

RSpec.describe "Profile", type: :request do
  let(:user) { create(:user) }

  describe "GET /account" do
    before { login_via_session(user) }

    it "renders the push notifications toggle" do
      get account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="push-notification"')
      expect(response.body).to include('data-push-notification-target="toggle"')
      expect(response.body).to include('data-action="change->push-notification#toggle"')
    end
  end
end
