require 'rails_helper'

RSpec.describe "BlogComments", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let(:blog_post) { create(:blog_post, challenge: challenge) }

  before do
    enrollment
    login_as user
  end

  describe "POST /challenges/:challenge_id/blog_posts/:blog_post_id/blog_comments" do
    context "with valid parameters" do
      let(:valid_attributes) { { content: "Great blog post!" } }

      it "creates a new comment" do
        expect {
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: valid_attributes }
        }.to change(BlogComment, :count).by(1)
      end

      it "sets the current user as the comment author" do
        post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: valid_attributes }
        expect(BlogComment.last.user).to eq(user)
      end

      it "redirects to the blog post" do
        post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: valid_attributes }
        expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { content: "" } }

      it "does not create a new comment" do
        expect {
          post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: invalid_attributes }
        }.not_to change(BlogComment, :count)
      end

      it "renders the blog post show template" do
        post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is not enrolled" do
      let(:other_challenge) { create(:challenge) }
      let(:other_post) { create(:blog_post, challenge: other_challenge) }

      it "redirects to root path" do
        post challenge_blog_post_blog_comments_path(other_challenge, other_post), params: { blog_comment: { content: "Test" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /challenges/:challenge_id/blog_posts/:blog_post_id/blog_comments/:id" do
    let!(:comment) { create(:blog_comment, blog_post: blog_post, user: user) }

    context "when user owns the comment" do
      it "destroys the comment" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, comment)
        }.to change(BlogComment, :count).by(-1)
      end

      it "redirects to the blog post" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, comment)
        expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
      end
    end

    context "when user is admin" do
      let(:admin_user) { create(:user, admin: true) }
      let(:other_user_comment) { create(:blog_comment, blog_post: blog_post) }

      before do
        logout
        create(:user_challenge_enrollment, user: admin_user, challenge: challenge)
        login_as admin_user
      end

      it "can delete any comment" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_user_comment)
        }.to change(BlogComment, :count).by(-1)
      end
    end

    context "when user does not own the comment and is not admin" do
      let(:other_user) { create(:user) }
      let(:other_comment) { create(:blog_comment, blog_post: blog_post, user: other_user) }

      it "does not delete the comment" do
        expect {
          delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_comment)
        }.not_to change(BlogComment, :count)
      end

      it "redirects with an alert" do
        delete challenge_blog_post_blog_comment_path(challenge, blog_post, other_comment)
        expect(response).to redirect_to(challenge_blog_post_path(challenge, blog_post))
        expect(flash[:alert]).to be_present
      end
    end
  end

  context "when user is not logged in" do
    before do
      logout
    end

    it "redirects to login" do
      post challenge_blog_post_blog_comments_path(challenge, blog_post), params: { blog_comment: { content: "Test" } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
