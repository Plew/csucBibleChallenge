class BlogPostsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :ensure_enrolled
  before_action :set_blog_post, only: [ :show ]

  def index
    @blog_posts = @challenge.blog_posts.visible.recent_first
  end

  def show
    @blog_comments = @blog_post.blog_comments.recent_first.includes(:user)
    @blog_comment = BlogComment.new
  end

  private

  def set_challenge
    @challenge = current_user.challenges.find(params[:challenge_id])
  end

  def ensure_enrolled
    unless current_user.challenges.include?(@challenge)
      redirect_to root_path, alert: t("blog_posts.not_enrolled")
    end
  end

  def set_blog_post
    @blog_post = @challenge.blog_posts.visible.find(params[:id])
  end
end
