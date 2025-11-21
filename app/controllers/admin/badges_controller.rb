class Admin::BadgesController < Admin::BaseController
  before_action :set_badge, only: [ :show, :edit, :update, :destroy ]

  def index
    @badges = Badge.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @badge = Badge.new
  end

  def create
    @badge = Badge.new(badge_params)

    if @badge.save
      redirect_to admin_badges_path, notice: t("admin.badges.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @badge.update(badge_params)
      redirect_to admin_badges_path, notice: t("admin.badges.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @badge.destroy
    redirect_to admin_badges_path, notice: t("admin.badges.deleted")
  end

  private

  def set_badge
    @badge = Badge.find(params[:id])
  end

  def badge_params
    params.require(:badge).permit(:name, :description, :icon)
  end
end
