class Admin::SprintsController < Admin::BaseController
  before_action :set_challenge
  before_action :set_sprint, only: [ :edit, :update, :destroy ]

  def index
    @sprints = @challenge.sprints.ordered
  end

  def new
    @sprint = @challenge.sprints.build
    @readings = @challenge.readings.order(:scheduled_date)
  end

  def create
    @sprint = @challenge.sprints.build(sprint_params)

    if @sprint.save
      redirect_to admin_challenge_sprints_path(@challenge), notice: t("admin.sprints.created")
    else
      @readings = @challenge.readings.order(:scheduled_date)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @readings = @challenge.readings.order(:scheduled_date)
  end

  def update
    if @sprint.update(sprint_params)
      redirect_to admin_challenge_sprints_path(@challenge), notice: t("admin.sprints.updated")
    else
      @readings = @challenge.readings.order(:scheduled_date)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sprint.destroy
    redirect_to admin_challenge_sprints_path(@challenge), notice: t("admin.sprints.deleted")
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_sprint
    @sprint = @challenge.sprints.find(params[:id])
  end

  def sprint_params
    params.require(:sprint).permit(:title, :begin_date, :end_date)
  end
end
