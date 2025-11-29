class BlogCommentsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :ensure_enrolled
  before_action :set_blog_post

  def create
    @blog_comment = @blog_post.blog_comments.build(blog_comment_params)
    @blog_comment.user = current_user

    if @blog_comment.save
      redirect_to challenge_blog_post_path(@challenge, @blog_post), notice: I18n.t("blog.comment_added")
    else
      @blog_comments = @blog_post.blog_comments.ordered
      @new_comment = @blog_comment
      render "blog_posts/show", status: :unprocessable_entity
    end
  end

  def destroy
    @blog_comment = @blog_post.blog_comments.find(params[:id])

    if @blog_comment.user == current_user || current_user.admin?
      @blog_comment.destroy
      redirect_to challenge_blog_post_path(@challenge, @blog_post), notice: I18n.t("blog.comment_deleted")
    else
      redirect_to challenge_blog_post_path(@challenge, @blog_post), alert: I18n.t("blog.comment_not_authorized")
    end
  end

  private

  def set_challenge
    @challenge = current_user.challenges.first
    redirect_to root_path, alert: I18n.t("blog.not_enrolled") unless @challenge
  end

  def ensure_enrolled
    unless current_user.challenges.include?(@challenge)
      redirect_to root_path, alert: I18n.t("blog.not_enrolled")
    end
  end

  def set_blog_post
    @blog_post = @challenge.blog_posts.visible.find(params[:blog_post_id])
  end

  def blog_comment_params
    params.require(:blog_comment).permit(:content)
  end

  def require_login
    unless logged_in?
      redirect_to new_user_session_path
    end
  end
end
