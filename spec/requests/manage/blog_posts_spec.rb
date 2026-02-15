require 'rails_helper'

RSpec.describe "Manage::BlogPosts", type: :request do
  let(:owner) { create(:user) }
  let(:challenge) { create(:challenge, creator: owner) }

  before { login_as owner }

  describe "GET /challenges/:challenge_id/manage/blog_posts" do
    it "returns success" do
      get challenge_manage_blog_posts_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays blog posts" do
      create(:blog_post, challenge: challenge, user: owner, title: "Test Post")
      get challenge_manage_blog_posts_path(challenge)
      expect(response.body).to include("Test Post")
    end
  end

  describe "GET /challenges/:challenge_id/manage/blog_posts/new" do
    it "returns success" do
      get new_challenge_manage_blog_post_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /challenges/:challenge_id/manage/blog_posts" do
    let(:valid_attributes) { { title: "New Post", content: "Content here", visible: true } }

    it "creates a blog post" do
      expect {
        post challenge_manage_blog_posts_path(challenge), params: { blog_post: valid_attributes }
      }.to change(BlogPost, :count).by(1)
    end

    it "assigns the current user as author" do
      post challenge_manage_blog_posts_path(challenge), params: { blog_post: valid_attributes }
      expect(BlogPost.last.user).to eq(owner)
    end
  end

  describe "PATCH /challenges/:challenge_id/manage/blog_posts/:id" do
    let(:blog_post) { create(:blog_post, challenge: challenge, user: owner, title: "Old") }

    it "updates the blog post" do
      patch challenge_manage_blog_post_path(challenge, blog_post), params: { blog_post: { title: "New" } }
      blog_post.reload
      expect(blog_post.title).to eq("New")
    end
  end

  describe "DELETE /challenges/:challenge_id/manage/blog_posts/:id" do
    let!(:blog_post) { create(:blog_post, challenge: challenge, user: owner) }

    it "destroys the blog post" do
      expect {
        delete challenge_manage_blog_post_path(challenge, blog_post)
      }.to change(BlogPost, :count).by(-1)
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { create(:user) }
    before { login_as other_user }

    it "denies access" do
      get challenge_manage_blog_posts_path(challenge)
      expect(response).to redirect_to(root_path)
    end
  end
end
