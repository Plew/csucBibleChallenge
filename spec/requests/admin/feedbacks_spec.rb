require 'rails_helper'

RSpec.describe "Admin::Feedbacks", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }

  def create_feedback(attrs = {})
    Feedback.create!({ category: :bug, subject: "Test subject", message: "Test message" }.merge(attrs))
  end

  describe "authorization" do
    context "when not logged in" do
      it "redirects to login for GET /admin/feedbacks" do
        get admin_feedbacks_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for GET /admin/feedbacks/:id" do
        feedback = create_feedback
        get admin_feedback_path(feedback)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/feedbacks" do
        get admin_feedbacks_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "when user is admin" do
    before { login_via_session(admin_user) }

    describe "GET /admin/feedbacks" do
      it "returns http success" do
        get admin_feedbacks_path
        expect(response).to have_http_status(:success)
      end

      it "shows manage feedback heading" do
        get admin_feedbacks_path
        expect(response.body).to include(I18n.t('admin.feedbacks.manage'))
      end

      it "shows total submissions stat" do
        get admin_feedbacks_path
        expect(response.body).to include(I18n.t('admin.feedbacks.total_submissions'))
      end

      context "with feedbacks" do
        let!(:feedback1) { create_feedback(subject: "Bug report", category: :bug) }
        let!(:feedback2) { create_feedback(subject: "A suggestion", category: :suggestion) }

        it "displays feedback subjects" do
          get admin_feedbacks_path
          expect(response.body).to include("Bug report")
          expect(response.body).to include("A suggestion")
        end

        it "includes view and delete action links" do
          get admin_feedbacks_path
          expect(response.body).to include(admin_feedback_path(feedback1))
        end

        context "with search filter" do
          it "filters by subject" do
            get admin_feedbacks_path, params: { search: "Bug report" }
            expect(response.body).to include("Bug report")
            expect(response.body).not_to include("A suggestion")
          end
        end
      end

      context "with no feedbacks" do
        it "shows no feedback message" do
          get admin_feedbacks_path
          expect(response.body).to include(I18n.t('admin.feedbacks.no_feedback'))
          expect(response.body).to include(I18n.t('admin.feedbacks.no_submissions'))
        end
      end
    end

    describe "GET /admin/feedbacks/:id" do
      let!(:feedback) { create_feedback(subject: "My bug", message: "Something broke") }

      it "returns http success" do
        get admin_feedback_path(feedback)
        expect(response).to have_http_status(:success)
      end

      it "shows feedback details heading" do
        get admin_feedback_path(feedback)
        expect(response.body).to include(I18n.t('admin.feedbacks.details'))
      end

      it "shows the feedback subject" do
        get admin_feedback_path(feedback)
        expect(response.body).to include("My bug")
      end

      it "shows the feedback message" do
        get admin_feedback_path(feedback)
        expect(response.body).to include("Something broke")
      end

      it "shows submission info section" do
        get admin_feedback_path(feedback)
        expect(response.body).to include(I18n.t('admin.feedbacks.submission_info'))
      end
    end

    describe "DELETE /admin/feedbacks/:id" do
      let!(:feedback) { create_feedback }

      it "deletes the feedback and redirects" do
        expect {
          delete admin_feedback_path(feedback), headers: { "HTTP_REFERER" => admin_feedbacks_path }
        }.to change(Feedback, :count).by(-1)
        expect(response).to redirect_to(admin_feedbacks_path)
      end
    end
  end
end
