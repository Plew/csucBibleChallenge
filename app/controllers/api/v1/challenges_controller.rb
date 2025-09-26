class Api::V1::ChallengesController < Api::BaseController
  before_action :set_challenge, only: [:show]

  # GET /api/v1/challenges
  def index
    @challenges = Challenge.where(hidden: false)
    render json: @challenges
  end

  # GET /api/v1/challenges/:id
  def show
    render json: @challenge
  end

  # POST /api/v1/challenges
  def create
    @challenge = Challenge.new(challenge_params)

    if @challenge.save
      render json: @challenge, status: :created
    else
      render json: { errors: @challenge.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Challenge not found' }, status: :not_found
  end

  def challenge_params
    params.require(:challenge).permit(:name, :start_date, :end_date)
  end
end
