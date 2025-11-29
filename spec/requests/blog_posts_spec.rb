require 'rails_helper'

RSpec.describe "BlogPosts", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }

  before do
    enrollment
    login_as user
  end

  describe "GET /challenges/:challenge_id/blog_posts" do
    let!(:visible_post) { create(:blog_post, challenge: challenge, visible: true, title: "Visible Post") }
    let!(:hidden_post) { create(:blog_post, challenge: challenge, visible: false, title: "Hidden Post") }

    it "returns success" do
      get challenge_blog_posts_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays only visible blog posts" do
      get challenge_blog_posts_path(challenge)
      expect(response.body).to include("Visible Post")
      expect(response.body).not_to include("Hidden Post")
    end

    context "when user is not enrolled in challenge" do
      let(:other_challenge) { create(:challenge) }

      it "redirects to root path" do
        get challenge_blog_posts_path(other_challenge)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /challenges/:challenge_id/blog_posts/:id" do
    let(:blog_post) { create(:blog_post, challenge: challenge, visible: true) }

    it "returns success" do
      get challenge_blog_post_path(challenge, blog_post)
      expect(response).to have_http_status(:success)
    end

    it "displays the blog post content" do
      get challenge_blog_post_path(challenge, blog_post)
      expect(response.body).to include(blog_post.title)
      expect(response.body).to include(blog_post.content)
    end

    it "displays comments" do
      comment = create(:blog_comment, blog_post: blog_post, content: "Great post!")
      get challenge_blog_post_path(challenge, blog_post)
      expect(response.body).to include("Great post!")
    end

    context "when post is hidden" do
      let(:hidden_post) { create(:blog_post, challenge: challenge, visible: false) }

      it "raises RecordNotFound" do
        expect {
          get challenge_blog_post_path(challenge, hidden_post)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is not enrolled" do
      let(:other_challenge) { create(:challenge) }
      let(:other_post) { create(:blog_post, challenge: other_challenge) }

      it "redirects to root path" do
        get challenge_blog_post_path(other_challenge, other_post)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context "when user is not logged in" do
    before do
      logout
    end

    it "redirects to login" do
      get challenge_blog_posts_path(challenge)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
