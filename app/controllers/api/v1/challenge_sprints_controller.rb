# Read-only sprint data for a challenge, authenticated by the challenge's API
# key. The index lists the challenge's sprints (dates, status, recorded
# winners); show returns the live ranked group standings for one sprint.
class Api::V1::ChallengeSprintsController < Api::BaseController
  include Api::ApiKeyAuthentication

  before_action :authenticate_challenge!
  before_action :set_sprint, only: :show

  # GET /api/v1/challenges/:challenge_id/sprints
  def index
    render json: SprintsReport.new(@challenge).as_json
  end

  # GET /api/v1/challenges/:challenge_id/sprints/:id
  def show
    render json: SprintStandings.new(@sprint).as_json
  end

  private

  def authenticate_challenge!
    authenticate_api_challenge!(params[:challenge_id])
  end

  def set_sprint
    @sprint = @challenge.sprints.find_by(id: params[:id])
    render json: { error: "Sprint not found in this challenge" }, status: :not_found unless @sprint
  end
end
