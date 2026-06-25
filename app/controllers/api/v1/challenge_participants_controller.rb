# Read-only per-participant detail for a challenge, authenticated by the
# challenge's API key. Returns the participant's full graph within this
# challenge: reading history, group memberships, likes, and comments.
class Api::V1::ChallengeParticipantsController < Api::BaseController
  include Api::ApiKeyAuthentication

  before_action :authenticate_challenge!
  before_action :set_participant

  # GET /api/v1/challenges/:challenge_id/participants/:id
  def show
    render json: ParticipantReport.new(@challenge, @enrollment).as_json
  end

  private

  def authenticate_challenge!
    authenticate_api_challenge!(params[:challenge_id])
  end

  def set_participant
    @enrollment = @challenge.user_challenge_enrollments.includes(:user).find_by(user_id: params[:id])
    render json: { error: "Participant not found in this challenge" }, status: :not_found unless @enrollment
  end
end
