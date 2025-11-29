require 'rails_helper'

RSpec.describe "Admin::BlogPosts", type: :request do
  let(:admin_user) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:challenge) { create(:challenge, creator: admin_user) }
  let!(:blog_post) { create(:blog_post, challenge: challenge, user: admin_user) }

  describe "authorization" do
    context "when user is not logged in" do
      it "redirects to login for GET /admin/challenges/:challenge_id/blog_posts" do
        get admin_challenge_blog_posts_path(challenge)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to login for POST /admin/challenges/:challenge_id/blog_posts" do
        post admin_challenge_blog_posts_path(challenge), params: { blog_post: { title: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { login_via_session(regular_user) }

      it "redirects to root for GET /admin/challenges/:challenge_id/blog_posts" do
        get admin_challenge_blog_posts_path(challenge)
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for POST /admin/challenges/:challenge_id/blog_posts" do
        post admin_challenge_blog_posts_path(challenge), params: { blog_post: { title: 'Test' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts" do
    before { login_via_session(admin_user) }

    let!(:visible_post) { create(:blog_post, challenge: challenge, user: admin_user, visible: true) }
    let!(:hidden_post) { create(:blog_post, challenge: challenge, user: admin_user, visible: false) }

    it "returns http success" do
      get admin_challenge_blog_posts_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays all blog posts including hidden ones" do
      get admin_challenge_blog_posts_path(challenge)
      expect(response.body).to include(visible_post.title)
      expect(response.body).to include(hidden_post.title)
    end
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts/new" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get new_admin_challenge_blog_post_path(challenge)
      expect(response).to have_http_status(:success)
    end

    it "displays the new blog post form" do
      get new_admin_challenge_blog_post_path(challenge)
      expect(response.body).to include(I18n.t("blog.new_post"))
    end
  end

  describe "POST /admin/challenges/:challenge_id/blog_posts" do
    before { login_via_session(admin_user) }

    context "with valid parameters" do
      let(:valid_params) do
        {
          blog_post: {
            title: 'New Blog Post',
            content: 'This is the content of the new blog post',
            visible: true
          }
        }
      end

      it "creates a new blog post" do
        expect {
          post admin_challenge_blog_posts_path(challenge), params: valid_params
        }.to change(BlogPost, :count).by(1)
      end

      it "assigns the current user as the author" do
        post admin_challenge_blog_posts_path(challenge), params: valid_params
        expect(BlogPost.last.user).to eq(admin_user)
      end

      it "redirects to blog posts index" do
        post admin_challenge_blog_posts_path(challenge), params: valid_params
        expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
      end

      it "displays success notice" do
        post admin_challenge_blog_posts_path(challenge), params: valid_params
        follow_redirect!
        expect(response.body).to include(I18n.t("blog.created"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          blog_post: {
            title: '',
            content: ''
          }
        }
      end

      it "does not create a blog post" do
        expect {
          post admin_challenge_blog_posts_path(challenge), params: invalid_params
        }.not_to change(BlogPost, :count)
      end

      it "renders new template with unprocessable entity status" do
        post admin_challenge_blog_posts_path(challenge), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/challenges/:challenge_id/blog_posts/:id/edit" do
    before { login_via_session(admin_user) }

    it "returns http success" do
      get edit_admin_challenge_blog_post_path(challenge, blog_post)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form" do
      get edit_admin_challenge_blog_post_path(challenge, blog_post)
      expect(response.body).to include(I18n.t("blog.edit_post"))
      expect(response.body).to include(blog_post.title)
    end
  end

  describe "PATCH /admin/challenges/:challenge_id/blog_posts/:id" do
    before { login_via_session(admin_user) }

    context "with valid parameters" do
      let(:valid_params) do
        {
          blog_post: {
            title: 'Updated Title',
            content: 'Updated content',
            visible: false
          }
        }
      end

      it "updates the blog post" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: valid_params
        blog_post.reload
        expect(blog_post.title).to eq('Updated Title')
        expect(blog_post.content).to eq('Updated content')
        expect(blog_post.visible).to be false
      end

      it "redirects to blog posts index" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: valid_params
        expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
      end

      it "displays success notice" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: valid_params
        follow_redirect!
        expect(response.body).to include(I18n.t("blog.updated"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          blog_post: {
            title: ''
          }
        }
      end

      it "does not update the blog post" do
        original_title = blog_post.title
        patch admin_challenge_blog_post_path(challenge, blog_post), params: invalid_params
        blog_post.reload
        expect(blog_post.title).to eq(original_title)
      end

      it "renders edit template with unprocessable entity status" do
        patch admin_challenge_blog_post_path(challenge, blog_post), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/challenges/:challenge_id/blog_posts/:id" do
    before { login_via_session(admin_user) }

    it "deletes the blog post" do
      blog_post # ensure it exists
      expect {
        delete admin_challenge_blog_post_path(challenge, blog_post)
      }.to change(BlogPost, :count).by(-1)
    end

    it "deletes associated comments" do
      create(:blog_comment, blog_post: blog_post)
      create(:blog_comment, blog_post: blog_post)

      expect {
        delete admin_challenge_blog_post_path(challenge, blog_post)
      }.to change(BlogComment, :count).by(-2)
    end

    it "redirects to blog posts index" do
      delete admin_challenge_blog_post_path(challenge, blog_post)
      expect(response).to redirect_to(admin_challenge_blog_posts_path(challenge))
    end

    it "displays success notice" do
      delete admin_challenge_blog_post_path(challenge, blog_post)
      follow_redirect!
      expect(response.body).to include(I18n.t("blog.deleted"))
    end
  end
end
