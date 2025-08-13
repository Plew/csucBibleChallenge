class Api::V1::ChallengeEnrollmentsController < Api::BaseController
  before_action :set_challenge
  before_action :set_enrollment, only: [:update]

  # POST /api/v1/challenges/:challenge_id/enrollments
  def create
    group_id = enrollment_params_for_create[:group_id]
    if group_id.present? && @challenge.groups.find_by(id: group_id).nil?
      return render json: { errors: ["Group must belong to the same challenge"] }, status: :unprocessable_content
    end

    enrollment = @challenge.user_challenge_enrollments.new(enrollment_params_for_create)

    if enrollment.save
      render json: enrollment, status: :created
    else
      render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH /api/v1/challenges/:challenge_id/enrollments/:id
  def update
    # Ensure the group_id, if provided, belongs to the same challenge
    if params_for_update[:group_id].present? && @challenge.groups.find_by(id: params_for_update[:group_id]).nil?
      return render json: { errors: ["Group must belong to the same challenge"] }, status: :unprocessable_content
    end
    
    if @enrollment.update(params_for_update)
      render json: @enrollment
    else
      render json: { errors: @enrollment.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_enrollment
    @enrollment = @challenge.user_challenge_enrollments.find(params[:id])
  end

  def enrollment_params_for_create
    params.require(:enrollment).permit(:user_id, :group_id)
  end

  def params_for_update # Renamed to avoid conflict with create params name
    params.require(:enrollment).permit(:group_id)
  end
end
