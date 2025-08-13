class Api::V1::GroupsController < Api::BaseController
  before_action :set_challenge

  # GET /api/v1/challenges/:challenge_id/groups
  def index
    @groups = @challenge.groups.order(:name)
    render json: @groups
  end

  # POST /api/v1/challenges/:challenge_id/groups
  def create
    @group = @challenge.groups.new(group_params)
    if @group.save
      render json: @group, status: :created
    else
      render json: { errors: @group.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def group_params
    params.require(:group).permit(:name)
  end
end
