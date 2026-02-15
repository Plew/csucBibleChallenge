class Manage::BlogPostsController < Manage::BaseController
  before_action :set_blog_post, only: [ :edit, :update, :destroy ]

  def index
    @blog_posts = @challenge.blog_posts.ordered
  end

  def new
    @blog_post = @challenge.blog_posts.build
  end

  def create
    @blog_post = @challenge.blog_posts.build(blog_post_params)
    @blog_post.user = current_user

    if @blog_post.save
      redirect_to challenge_manage_blog_posts_path(@challenge), notice: t("blog.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @blog_post.update(blog_post_params)
      redirect_to challenge_manage_blog_posts_path(@challenge), notice: t("blog.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog_post.destroy
    redirect_to challenge_manage_blog_posts_path(@challenge), notice: t("blog.deleted")
  end

  private

  def set_blog_post
    @blog_post = @challenge.blog_posts.find(params[:id])
  end

  def blog_post_params
    params.require(:blog_post).permit(:title, :content, :visible, :image)
  end
end
