class Admin::StatWindowsController < Admin::BaseController
  before_action :set_challenge
  before_action :set_stat_window, only: [ :edit, :update, :destroy ]

  def index
    @stat_windows = @challenge.stat_windows.ordered
  end

  def new
    @stat_window = @challenge.stat_windows.build
  end

  def create
    @stat_window = @challenge.stat_windows.build(stat_window_params)

    if @stat_window.save
      redirect_to admin_challenge_stat_windows_path(@challenge), notice: t("admin.stat_windows.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @stat_window.update(stat_window_params)
      redirect_to admin_challenge_stat_windows_path(@challenge), notice: t("admin.stat_windows.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stat_window.destroy
    redirect_to admin_challenge_stat_windows_path(@challenge), notice: t("admin.stat_windows.deleted")
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_stat_window
    @stat_window = @challenge.stat_windows.find(params[:id])
  end

  def stat_window_params
    params.require(:stat_window).permit(:title, :begin_date, :end_date)
  end
end
