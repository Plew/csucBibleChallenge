require "csv"

class Manage::GroupsController < Manage::BaseController
  before_action :set_group, only: [ :update, :destroy, :remove_member, :move_member ]

  def index
    load_groups_and_stats

    respond_to do |format|
      format.html
      format.csv do
        send_data generate_groups_csv(@groups_with_stats),
                  filename: "#{@challenge.name.parameterize}-group-stats-#{@group_statistics.today}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end
  end

  def update
    if @group.update(group_params)
      redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.renamed", name: @group.name)
    else
      load_groups_and_stats
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.deleted", name: @group.name)
  end

  def remove_member
    enrollment = @group.user_group_enrollments.find_by(user_id: params[:user_id])
    if enrollment
      user = enrollment.user
      enrollment.destroy
      if @group.creator_id == user.id
        @group.transfer_ownership_to_first_joined!
      end
      redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.member_removed", username: user.username)
    else
      redirect_to challenge_manage_groups_path(@challenge), alert: t("manage.groups.member_not_in_group")
    end
  end

  def move_member
    enrollment = @group.user_group_enrollments.find_by(user_id: params[:user_id])
    target_group = @challenge.groups.find(params[:target_group_id])

    if enrollment
      user = enrollment.user
      ActiveRecord::Base.transaction do
        enrollment.destroy
        user.user_group_enrollments.create!(group: target_group)
        if @group.creator_id == user.id
          @group.transfer_ownership_to_first_joined!
        end
      end
      redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.member_moved", username: user.username, group: target_group.name)
    else
      redirect_to challenge_manage_groups_path(@challenge), alert: t("manage.groups.member_not_in_group")
    end
  end

  private

  def set_group
    @group = @challenge.groups.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name)
  end

  def load_groups_and_stats
    @groups = @challenge.groups.includes(:users).order(:name)
    @group_statistics = ManageGroupStatistics.new(@challenge, @groups)
    @groups_with_stats = @group_statistics.rows
    @participant_stats = @group_statistics.participants.by_user_id
    @stats_by_group_id = @groups_with_stats.index_by { |row| row[:group].id }
  end

  def generate_groups_csv(groups_with_stats)
    CSV.generate(headers: true) do |csv|
      csv << [ "Rank", "Group Name", "Members", "On Target %", "Completion %",
               "Completed Readings", "Missing Readings", "Caught Up Members",
               "Active Members (Last 7 Days)", "Members With No Completed Readings",
               "Last Activity", "Readings Due Per Member", "As Of", "Timezone", "Stats Start", "Stats Through" ]
      groups_with_stats.each_with_index do |data, index|
        csv << [
          index + 1,
          SpreadsheetCsv.safe_text(data[:group].name),
          data[:member_count],
          data[:on_schedule_percentage],
          data[:completion_percentage],
          data[:completed_readings], data[:missing_readings], data[:caught_up_members],
          data[:active_members], data[:not_started_members], data[:last_activity],
          @group_statistics.scheduled_count, @group_statistics.today, @challenge.timezone,
          @challenge.stats_start_date, @group_statistics.through_date
        ]
      end
    end
  end
end
