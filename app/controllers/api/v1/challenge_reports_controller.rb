# Read-only challenge data API, authenticated by a per-challenge API key passed
# as `Authorization: Bearer <key>`. The key is generated/viewed by challenge
# organizers in the management console (Manage::ApiAccessController) and only
# grants access to its own challenge.
class Api::V1::ChallengeReportsController < Api::BaseController
  include Api::ApiKeyAuthentication

  before_action :authenticate_challenge!

  # GET /api/v1/challenges/:id/report
  def show
    render json: ChallengeReport.new(@challenge).as_json
  end

  private

  def authenticate_challenge!
    authenticate_api_challenge!(params[:id])
  end
end
