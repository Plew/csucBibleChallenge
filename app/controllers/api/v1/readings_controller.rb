class Api::V1::ReadingsController < Api::BaseController
  before_action :set_challenge

  # GET /api/v1/challenges/:challenge_id/readings
  def index
    @readings = @challenge.readings.order(:scheduled_date, :created_at)
    render json: @readings
  end

  # POST /api/v1/challenges/:challenge_id/readings
  def create
    @reading = @challenge.readings.new(reading_params)

    if @reading.save
      render json: @reading, status: :created
    else
      render json: { errors: @reading.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def reading_params
    params.require(:reading).permit(:title, :scheduled_date)
  end
end
