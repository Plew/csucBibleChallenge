require 'rails_helper'

RSpec.describe "BlogPosts", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:visible_post) { create(:blog_post, challenge: challenge, visible: true) }
  let!(:hidden_post) { create(:blog_post, challenge: challenge, visible: false) }

  describe "GET /challenges/:challenge_id/blog_posts" do
    context "when user is logged in and enrolled" do
      before { login_via_session(user) }

      it "returns http success" do
        get challenge_blog_posts_path(challenge)
        expect(response).to have_http_status(:success)
      end

      it "displays only visible blog posts" do
        get challenge_blog_posts_path(challenge)
        expect(response.body).to include(visible_post.title)
        expect(response.body).not_to include(hidden_post.title)
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get challenge_blog_posts_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not enrolled in any challenge" do
      let(:unenrolled_user) { create(:user) }

      before { login_via_session(unenrolled_user) }

      it "redirects with alert" do
        get challenge_blog_posts_path(challenge)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("blog.not_enrolled"))
      end
    end
  end

  describe "GET /challenges/:challenge_id/blog_posts/:id" do
    context "when user is logged in and enrolled" do
      before { login_via_session(user) }

      it "returns http success" do
        get challenge_blog_post_path(challenge, visible_post)
        expect(response).to have_http_status(:success)
      end

      it "displays the blog post with comments" do
        comment = create(:blog_comment, blog_post: visible_post)
        get challenge_blog_post_path(challenge, visible_post)

        expect(response.body).to include(visible_post.title)
        expect(response.body).to include(comment.content)
      end

      it "cannot access hidden posts" do
        get challenge_blog_post_path(challenge, hidden_post)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get challenge_blog_post_path(challenge, visible_post)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
