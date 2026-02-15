class Manage::SprintsController < Manage::BaseController
  before_action :set_sprint, only: [ :show, :edit, :update, :destroy ]

  def index
    @sprints = @challenge.sprints.ordered
  end

  def show
    groups = @challenge.groups.includes(:users)

    @groups_with_stats = groups.map do |group|
      stats = GroupStatistics.new(group, @sprint.date_range)
      {
        group: group,
        completion_percentage: stats.completion_percentage,
        on_schedule_percentage: stats.on_schedule_percentage,
        member_count: group.users.count
      }
    end

    @groups_with_stats.sort_by! do |g|
      [ -g[:completion_percentage], -g[:on_schedule_percentage], -g[:member_count] ]
    end
  end

  def new
    @sprint = @challenge.sprints.build
    @readings = @challenge.readings.order(:scheduled_date)
  end

  def create
    @sprint = @challenge.sprints.build(sprint_params)

    if @sprint.save
      redirect_to challenge_manage_sprints_path(@challenge), notice: t("manage.sprints.created")
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
      redirect_to challenge_manage_sprints_path(@challenge), notice: t("manage.sprints.updated")
    else
      @readings = @challenge.readings.order(:scheduled_date)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sprint.destroy
    redirect_to challenge_manage_sprints_path(@challenge), notice: t("manage.sprints.deleted")
  end

  private

  def set_sprint
    @sprint = @challenge.sprints.find(params[:id])
  end

  def sprint_params
    params.require(:sprint).permit(:title, :begin_date, :end_date)
  end
end
