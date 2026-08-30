require 'rails_helper'

RSpec.describe "Static Pages", type: :request do
  describe "GET /privacy" do
    it "returns http success" do
      get privacy_path
      expect(response).to have_http_status(:success)
    end

    it "contains privacy policy contents" do
      get privacy_path
      expect(response.body).to include("Privacy Policy")
      expect(response.body).to include("Information We Collect")
      expect(response.body).to include("Email Communications")
      expect(response.body).to include("support@andgodsaid.org")
    end

    it "is accessible without login" do
      get privacy_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe "GET /terms" do
    it "returns http success" do
      get terms_path
      expect(response).to have_http_status(:success)
    end

    it "contains terms of service contents" do
      get terms_path
      expect(response.body).to include("Terms of Service")
      expect(response.body).to include("Community Guidelines")
      expect(response.body).to include("Scripture Content")
    end

    it "is accessible without login" do
      get terms_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe "GET /contact" do
    it "returns http success" do
      get contact_path
      expect(response).to have_http_status(:success)
    end

    it "contains contact details" do
      get contact_path
      expect(response.body).to include("Contact Us")
      expect(response.body).to include("support@andgodsaid.org")
      expect(response.body).to include(new_feedback_path)
    end

    it "is accessible without login" do
      get contact_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe "Footer and Menu Links" do
    it "renders footer links on pages" do
      get root_path
      expect(response.body).to include(privacy_path)
      expect(response.body).to include(terms_path)
      expect(response.body).to include(contact_path)
      expect(response.body).to include(about_path)
      expect(response.body).to include(faq_path)
    end
  end
end
