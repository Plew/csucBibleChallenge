class Api::V1::UserReadingsController < Api::BaseController
  # POST /api/v1/user_readings
  # Params: { user_reading: { user_id: X, reading_id: Y, completed_on: DATE } }
  # If completed_on is not provided, it defaults to Date.today
  def create
    # Ensure user and reading exist before attempting to create the join record
    user = User.find_by(id: user_reading_params[:user_id])
    unless user
      return render json: { errors: ["User not found"] }, status: :not_found
    end

    reading = Reading.find_by(id: user_reading_params[:reading_id])
    unless reading
      return render json: { errors: ["Reading not found"] }, status: :not_found
    end

    # Ensure the user is enrolled in the challenge to which the reading belongs (optional, for stricter access)
    # unless user.challenges.include?(reading.challenge)
    #   return render json: { errors: ["User not enrolled in the challenge for this reading"] }, status: :forbidden
    # end

    @user_reading = UserReading.new(user_reading_params)
    @user_reading.completed_on ||= Date.today # Default to today if not provided

    if @user_reading.save
      render json: @user_reading, status: :created
    else
      render json: { errors: @user_reading.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/user_readings/:id
  # OR DELETE /api/v1/user_readings?user_id=X&reading_id=Y (Alternative, not implemented here)
  def destroy
    @user_reading = UserReading.find_by(id: params[:id])
    if @user_reading
      @user_reading.destroy
      head :no_content # Successful deletion, no content to return
    else
      render json: { error: "UserReading record not found" }, status: :not_found
    end
  end

  private

  def user_reading_params
    params.require(:user_reading).permit(:user_id, :reading_id, :completed_on)
  end
end
