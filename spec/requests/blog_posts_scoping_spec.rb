require 'rails_helper'

RSpec.describe "BlogPosts Challenge Scoping", type: :request do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge) }
  let(:other_challenge) { create(:challenge) }
  let!(:enrollment) { create(:user_challenge_enrollment, user: user, challenge: challenge) }
  let!(:post_in_challenge) { create(:blog_post, challenge: challenge, visible: true) }
  let!(:post_in_other) { create(:blog_post, challenge: other_challenge, visible: true) }

  before { login_via_session(user) }

  describe "GET /challenges/:challenge_id/blog_posts" do
    it "loads posts from the correct challenge" do
      get challenge_blog_posts_path(challenge)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(post_in_challenge.title)
      expect(response.body).not_to include(post_in_other.title)
    end

    it "rejects access to a challenge the user is not enrolled in" do
      get challenge_blog_posts_path(other_challenge)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /challenges/:challenge_id/blog_posts/:id" do
    it "shows a post from the enrolled challenge" do
      get challenge_blog_post_path(challenge, post_in_challenge)
      expect(response).to have_http_status(:success)
    end

    it "cannot access a post from a different challenge via URL manipulation" do
      # post_in_other belongs to other_challenge, so looking it up via challenge's blog_posts scope should 404
      get challenge_blog_post_path(challenge, post_in_other)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when user is not enrolled in any challenge" do
    let(:unenrolled_user) { create(:user) }

    before { login_via_session(unenrolled_user) }

    it "blocks access to any challenge's blog posts" do
      get challenge_blog_posts_path(challenge)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("blog.not_enrolled"))
    end
  end
end
