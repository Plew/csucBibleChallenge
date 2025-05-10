class Api::V1::ChallengeEnrollmentsController < Api::BaseController
  before_action :set_challenge

  # POST /api/v1/challenges/:challenge_id/enrollments
  def create
    enrollment = @challenge.user_challenge_enrollments.new(user_id: enrollment_params[:user_id])

    if enrollment.save
      render json: enrollment, status: :created
    else
      render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def enrollment_params
    params.require(:enrollment).permit(:user_id)
  end
end
