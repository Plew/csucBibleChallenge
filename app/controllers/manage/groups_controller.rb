class Manage::GroupsController < Manage::BaseController
  before_action :set_group, only: [ :update, :destroy, :remove_member, :move_member ]

  def index
    @groups = @challenge.groups.includes(:users).order(:name)
  end

  def update
    if @group.update(group_params)
      redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.renamed", name: @group.name)
    else
      @groups = @challenge.groups.includes(:users).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.deleted", name: @group.name)
  end

  def remove_member
    user = @challenge.users.find(params[:user_id])
    enrollment = user.user_group_enrollments.find_by(group: @group)
    if enrollment
      enrollment.destroy
      redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.member_removed", username: user.username)
    else
      redirect_to challenge_manage_groups_path(@challenge), alert: t("manage.groups.member_not_in_group")
    end
  end

  def move_member
    user = @challenge.users.find(params[:user_id])
    target_group = @challenge.groups.find(params[:target_group_id])

    ActiveRecord::Base.transaction do
      user.user_group_enrollments.joins(:group).where(groups: { challenge_id: @challenge.id }).delete_all
      user.user_group_enrollments.create!(group: target_group)
    end

    redirect_to challenge_manage_groups_path(@challenge), notice: t("manage.groups.member_moved", username: user.username, group: target_group.name)
  end

  private

  def set_group
    @group = @challenge.groups.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name)
  end
end
