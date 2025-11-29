require 'rails_helper'

RSpec.describe "Admin::BlogPosts", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:challenge) { create(:challenge, creator: admin_user) }

  before do
    login_as admin_user
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts" do
    it "returns success" do
      get admin_challenge_blog_posts_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays blog posts for the challenge" do
      blog_post = create(:blog_post, challenge: challenge, title: "Test Blog Post")
      get admin_challenge_blog_posts_path(challenge)
      expect(response.body).to include("Test Blog Post")
    end
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts/new" do
    it "returns success" do
      get new_admin_challenge_blog_post_path(challenge)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/challenges/:challenge_id/blog_posts" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          title: "My First Blog Post",
          content: "This is the content of my **blog post** with markdown.",
          visible: true
        }
      end

      it "creates a new blog post" do
        expect {
          post admin_challenge_blog_posts_path(challenge), params: { blog_post: valid_attributes }
        }.to change(BlogPost, :count).by(1)
      end

      it "sets the current user as the author" do
        post admin_challenge_blog_posts_path(challenge), params: { blog_post: valid_attributes }
        expect(BlogPost.last.user).to eq(admin_user)
      end

      it "redirects to the blog posts index" do
        post admin_challenge_blog_posts_path(challenge), params: { blog_post: valid_attributes }
        expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          title: "",
          content: "",
          visible: true
        }
      end

      it "does not create a new blog post" do
        expect {
          post admin_challenge_blog_posts_path(challenge), params: { blog_post: invalid_attributes }
        }.not_to change(BlogPost, :count)
      end

      it "renders the new template" do
        post admin_challenge_blog_posts_path(challenge), params: { blog_post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts/:id/edit" do
    let(:blog_post) { create(:blog_post, challenge: challenge) }

    it "returns success" do
      get edit_admin_challenge_blog_post_path(challenge, blog_post)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/challenges/:challenge_id/blog_posts/:id" do
    let(:blog_post) { create(:blog_post, challenge: challenge, title: "Old Title") }

    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated Title", visible: false } }

      it "updates the blog post" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: { blog_post: new_attributes }
        blog_post.reload
        expect(blog_post.title).to eq("Updated Title")
        expect(blog_post.visible).to be false
      end

      it "redirects to the blog posts index" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: { blog_post: new_attributes }
        expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { title: "", content: "" } }

      it "does not update the blog post" do
        original_title = blog_post.title
        patch admin_challenge_blog_post_path(challenge, blog_post), params: { blog_post: invalid_attributes }
        blog_post.reload
        expect(blog_post.title).to eq(original_title)
      end

      it "renders the edit template" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: { blog_post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/challenges/:challenge_id/blog_posts/:id" do
    let!(:blog_post) { create(:blog_post, challenge: challenge) }

    it "destroys the blog post" do
      expect {
        delete admin_challenge_blog_post_path(challenge, blog_post)
      }.to change(BlogPost, :count).by(-1)
    end

    it "redirects to the blog posts index" do
      delete admin_challenge_blog_post_path(challenge, blog_post)
      expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
    end
  end

  context "when user is not admin" do
    let(:regular_user) { create(:user, admin: false) }

    before do
      logout
      login_as regular_user
    end

    it "denies access to blog post management" do
      get admin_challenge_blog_posts_path(challenge)
      expect(response).to redirect_to(root_path)
    end
  end
end
