# Read-only per-group detail for a challenge, authenticated by the challenge's
# API key. Returns the group's full graph within this challenge: profile,
# members with their progress, aggregate stats, and per-sprint performance.
class Api::V1::GroupReportsController < Api::BaseController
  include Api::ApiKeyAuthentication

  before_action :authenticate_challenge!
  before_action :set_group

  # GET /api/v1/challenges/:challenge_id/groups/:id/report
  def show
    render json: GroupReport.new(@challenge, @group).as_json
  end

  private

  def authenticate_challenge!
    authenticate_api_challenge!(params[:challenge_id])
  end

  def set_group
    @group = @challenge.groups.find_by(id: params[:id])
    render json: { error: "Group not found in this challenge" }, status: :not_found unless @group
  end
end
