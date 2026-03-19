class Admin::SprintsController < Admin::BaseController
  before_action :set_challenge
  before_action :set_sprint, only: [ :show, :edit, :update, :destroy ]

  def index
    @sprints = @challenge.sprints.ordered
  end

  def show
    # Get all groups for this challenge
    groups = @challenge.groups.includes(:users)

    # Calculate statistics for each group within the sprint date range
    @groups_with_stats = groups.map do |group|
      stats = GroupStatistics.new(group, @sprint.date_range)
      {
        group: group,
        completion_percentage: stats.completion_percentage,
        on_schedule_percentage: stats.on_schedule_percentage,
        member_count: group.users.count
      }
    end

    # Sort by: completion_percentage (desc), on_schedule_percentage (desc), member_count (desc)
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
      redirect_to admin_challenge_sprints_path(@challenge), notice: t("admin.sprints.created")
    else
      @readings = @challenge.readings.order(:scheduled_date)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @readings = @challenge.readings.order(:scheduled_date)
    @groups = @challenge.groups.order(:name) if @sprint.end_date < Date.current
  end

  def update
    ActiveRecord::Base.transaction do
      assign_winner_groups! if params[:sprint].key?(:winner_group_ids)
      unless @sprint.update(sprint_params)
        @readings = @challenge.readings.order(:scheduled_date)
        @groups = @challenge.groups.order(:name) if @sprint.end_date < Date.current
        raise ActiveRecord::Rollback
      end
    end

    if @sprint.errors.any?
      render :edit, status: :unprocessable_entity
    else
      redirect_back_or_to admin_challenge_sprints_path(@challenge), notice: t("admin.sprints.updated")
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

  def assign_winner_groups!
    group_ids = Array(params[:sprint][:winner_group_ids]).reject(&:blank?).map(&:to_i)
    @sprint.sprint_winners.destroy_all

    group_ids.each do |group_id|
      group = @challenge.groups.find(group_id)
      stats = GroupStatistics.new(group, @sprint.date_range)
      @sprint.sprint_winners.create!(
        group: group,
        group_name: group.name,
        completion_percentage: stats.completion_percentage,
        on_schedule_percentage: stats.on_schedule_percentage
      )
    end
  end
end
