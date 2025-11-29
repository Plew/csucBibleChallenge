class Admin::BlogPostsController < Admin::BaseController
  before_action :set_challenge
  before_action :set_blog_post, only: [ :edit, :update, :destroy ]

  def index
    @blog_posts = @challenge.blog_posts.recent_first
  end

  def new
    @blog_post = @challenge.blog_posts.build
  end

  def create
    @blog_post = @challenge.blog_posts.build(blog_post_params)
    @blog_post.user = current_user

    if @blog_post.save
      redirect_to admin_challenge_blog_posts_path(@challenge), notice: t("admin.blog_posts.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @blog_post.update(blog_post_params)
      redirect_to admin_challenge_blog_posts_path(@challenge), notice: t("admin.blog_posts.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog_post.destroy
    redirect_to admin_challenge_blog_posts_path(@challenge), notice: t("admin.blog_posts.deleted")
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_blog_post
    @blog_post = @challenge.blog_posts.find(params[:id])
  end

  def blog_post_params
    params.require(:blog_post).permit(:title, :content, :visible)
  end
end
