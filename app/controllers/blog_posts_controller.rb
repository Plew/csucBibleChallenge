class BlogPostsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :ensure_enrolled
  before_action :set_blog_post, only: [ :show ]

  def index
    @blog_posts = @challenge.blog_posts.visible.ordered
  end

  def show
    @blog_comments = @blog_post.blog_comments.ordered
    @new_comment = @blog_post.blog_comments.build
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: I18n.t("blog.not_enrolled")
  end

  def ensure_enrolled
    unless current_user.challenges.include?(@challenge)
      redirect_to root_path, alert: I18n.t("blog.not_enrolled")
    end
  end

  def set_blog_post
    @blog_post = @challenge.blog_posts.visible.find(params[:id])
  end

  def require_login
    unless logged_in?
      redirect_to new_user_session_path
    end
  end
end
