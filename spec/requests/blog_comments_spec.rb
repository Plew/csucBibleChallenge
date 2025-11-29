require 'rails_helper'

RSpec.describe "BlogComments", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:challenge) { create(:challenge) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:other_enrollment) { create(:user_challenge_enrollment, user: other_user, challenge: challenge) }
  let!(:admin_enrollment) { create(:user_challenge_enrollment, user: admin_user, challenge: challenge) }
  let!(:blog_post) { create(:blog_post, challenge: challenge, visible: true) }

  describe "POST /challenges/:challenge_id/blog_posts/:blog_post_id/blog_comments" do
    context "when user is logged in and enrolled" do
      before { login_via_session(user) }

      context "with valid parameters" do
        let(:valid_params) do
          {
            blog_comment: {
              content: 'This is a test comment'
            }
          }
        end

        it "creates a new comment" do
          expect {
            post challenge_blog_post_blog_comments_path(challenge, blog_post), params: valid_params
          }.to change(BlogComment, :count).by(1)
        end

        it "assigns the current user as the comment author" do
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: valid_params
          expect(BlogComment.last.user).to eq(user)
        end

        it "redirects to the blog post" do
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: valid_params
          expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
        end

        it "displays success notice" do
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: valid_params
          follow_redirect!
          expect(response.body).to include(I18n.t("blog.comment_added"))
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            blog_comment: {
              content: ''
            }
          }
        end

        it "does not create a comment" do
          expect {
            post challenge_blog_post_blog_comments_path(challenge, blog_post), params: invalid_params
          }.not_to change(BlogComment, :count)
        end

        it "renders the blog post show template" do
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        post challenge_blog_post_blog_comments_path(challenge, blog_post),
             params: { blog_comment: { content: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /challenges/:challenge_id/blog_posts/:blog_post_id/blog_comments/:id" do
    let!(:user_comment) { create(:blog_comment, blog_post: blog_post, user: user) }
    let!(:other_comment) { create(:blog_comment, blog_post: blog_post, user: other_user) }

    context "when user is the comment author" do
      before { login_via_session(user) }

      it "deletes their own comment" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, user_comment)
        }.to change(BlogComment, :count).by(-1)
      end

      it "redirects to the blog post" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, user_comment)
        expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
      end

      it "displays success notice" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, user_comment)
        follow_redirect!
        expect(response.body).to include(I18n.t("blog.comment_deleted"))
      end

      it "cannot delete other users' comments" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_comment)
        }.not_to change(BlogComment, :count)

        expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
        expect(flash[:alert]).to eq(I18n.t("blog.comment_not_authorized"))
      end
    end

    context "when user is an admin" do
      before { login_via_session(admin_user) }

      it "can delete any comment" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_comment)
        }.to change(BlogComment, :count).by(-1)
      end

      it "displays success notice" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_comment)
        follow_redirect!
        expect(response.body).to include(I18n.t("blog.comment_deleted"))
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, user_comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
