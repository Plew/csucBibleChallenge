class BlogCommentsController < ApplicationController
  before_action :require_login
  before_action :set_blog_post
  before_action :ensure_enrolled

  def create
    @blog_comment = @blog_post.blog_comments.build(blog_comment_params)
    @blog_comment.user = current_user

    if @blog_comment.save
      redirect_to challenge_blog_post_path(@blog_post.challenge, @blog_post), notice: t("blog_comments.created")
    else
      @blog_comments = @blog_post.blog_comments.recent_first.includes(:user)
      render "blog_posts/show", status: :unprocessable_entity
    end
  end

  def destroy
    @blog_comment = @blog_post.blog_comments.find(params[:id])

    # Only allow user to delete their own comments or admin
    if @blog_comment.user == current_user || current_user.admin?
      @blog_comment.destroy
      redirect_to challenge_blog_post_path(@blog_post.challenge, @blog_post), notice: t("blog_comments.deleted")
    else
      redirect_to challenge_blog_post_path(@blog_post.challenge, @blog_post), alert: t("blog_comments.unauthorized")
    end
  end

  private

  def set_blog_post
    @blog_post = BlogPost.find(params[:blog_post_id])
  end

  def ensure_enrolled
    unless current_user.challenges.include?(@blog_post.challenge)
      redirect_to root_path, alert: t("blog_posts.not_enrolled")
    end
  end

  def blog_comment_params
    params.require(:blog_comment).permit(:content)
  end
end
