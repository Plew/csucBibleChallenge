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
    challenge = api_key_challenge

    if challenge.nil?
      render_invalid_api_key
    elsif challenge.id.to_s != params[:id].to_s
      # The key is valid but for a different challenge — don't expose other data.
      render json: { error: "API key is not valid for this challenge" }, status: :forbidden
    else
      @challenge = challenge
    end
  end
end
