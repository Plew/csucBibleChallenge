class Api::V1::UserReadingsController < Api::BaseController
  before_action :set_reading, only: [ :create ] # For nested routes
  before_action :set_user_reading_by_id, only: [ :destroy_by_id ] # For DELETE /user_readings/:id
  before_action :set_reading_for_destroy, only: [ :destroy ]
  before_action :set_user_reading_by_reading, only: [ :destroy ] # For DELETE /readings/:reading_id/user_reading

  # GET /api/v1/user_readings
  # Lists UserReadings for the current_user
  def index
    @user_readings = current_user.user_readings.includes(:reading) # Eager load reading
    render json: @user_readings, include: :reading
  end

  # POST /api/v1/readings/:reading_id/user_reading
  # Creates a UserReading for the current_user and the specified reading
  def create
    challenge = @reading.challenge
    unless challenge&.timezone.present?
      return render json: { errors: [ "Challenge timezone not set for this reading." ] }, status: :unprocessable_content
    end

    current_date_in_challenge_tz = Time.current.in_time_zone(challenge.timezone).to_date
    scheduled_date = @reading.scheduled_date

    if current_date_in_challenge_tz < scheduled_date
      return render json: { errors: [ "Cannot mark readings for future dates. This reading is scheduled for #{scheduled_date}. Current date in timezone is #{current_date_in_challenge_tz}." ] }, status: :forbidden
    end

    @user_reading = UserReading.new(user: current_user, reading: @reading, completed_on: current_date_in_challenge_tz)

    if @user_reading.save
      render json: @user_reading, status: :created
    else
      # Check if the error is due to uniqueness constraint
      if @user_reading.errors[:user_id].any? { |e| e.include?("has already marked this reading") }
        existing_reading = UserReading.find_by(user: current_user, reading: @reading)
        render json: { errors: [ "You have already marked this reading." ], user_reading: existing_reading }, status: :conflict
      else
        render json: { errors: @user_reading.errors.full_messages }, status: :unprocessable_content
      end
    end
  end

  # DELETE /api/v1/readings/:reading_id/user_reading
  # Destroys a UserReading for the current_user and the specified reading
  # Renaming from 'destroy' to avoid conflict if top-level destroy is kept separate
  def destroy # This will handle DELETE /readings/:reading_id/user_reading due to routes
    # Timezone validation for un-checking
    challenge = @user_reading.reading.challenge # @user_reading is set by before_action
    unless challenge&.timezone.present?
      return render json: { errors: [ "Challenge timezone not set for this reading." ] }, status: :unprocessable_content
    end

    current_date_in_challenge_tz = Time.current.in_time_zone(challenge.timezone).to_date
    scheduled_date = @user_reading.reading.scheduled_date

    unless current_date_in_challenge_tz == scheduled_date
      return render json: { errors: [ "Un-checking is only allowed on the scheduled date of the reading (#{scheduled_date}) in the challenge's timezone (#{challenge.timezone}). Current date in timezone is #{current_date_in_challenge_tz}." ] }, status: :forbidden
    end

    @user_reading.destroy # @user_reading is set by set_user_reading_by_reading
    head :no_content
  end

  # POST /api/v1/user_readings (If still needed for other purposes, e.g. admin, or different params)
  # This is the original create action, may need to be adjusted or removed if
  # all user check-ins go through /readings/:reading_id/user_reading
  def create_legacy
    # Ensure user and reading exist before attempting to create the join record
    user = User.find_by(id: user_reading_params[:user_id])
    return render json: { errors: [ "User not found" ] }, status: :not_found unless user

    reading = Reading.find_by(id: user_reading_params[:reading_id])
    return render json: { errors: [ "Reading not found" ] }, status: :not_found unless reading

    # Potentially add timezone validation here if this route is still used for user check-ins
    # For now, assumes it might be an admin or different type of operation

    @user_reading = UserReading.new(user_reading_params)
    # Original logic: @user_reading.completed_on ||= Date.today
    # If this is a user check-in, it should respect the challenge timezone and reading date.
    # completed_on should probably be required in params or derived carefully.
    unless user_reading_params[:completed_on]
        return render json: { errors: [ "completed_on is required for this action" ] }, status: :unprocessable_content
    end


    if @user_reading.save
      render json: @user_reading, status: :created
    else
      render json: { errors: @user_reading.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /api/v1/user_readings/:id
  # This is the original destroy action.
  def destroy_legacy
    # @user_reading set by set_user_reading_by_id
    # Ensure current_user owns this or is an admin
    unless @user_reading.user == current_user # Or admin check
        return render json: { error: "Forbidden" }, status: :forbidden
    end

    # Potentially add timezone validation here if this route is still used for user check-ins
    # For now, assumes it might be an admin or different type of operation

    @user_reading.destroy
    head :no_content
  end


  private

  def set_reading
    @reading = Reading.find_by(id: params[:reading_id])
    render json: { errors: [ "Reading not found" ] }, status: :not_found unless @reading
  end

  def set_reading_for_destroy
    @reading = Reading.find_by(id: params[:reading_id])
    render json: { errors: [ "Reading not found" ] }, status: :not_found unless @reading
  end

  def set_user_reading_by_id
    @user_reading = UserReading.find_by(id: params[:id])
    render json: { error: "UserReading record not found" }, status: :not_found unless @user_reading
  end

  def set_user_reading_by_reading
    # For DELETE /readings/:reading_id/user_reading
    # Assumes @reading is already set by set_reading_for_destroy
    @user_reading = UserReading.find_by(user: current_user, reading: @reading)
    render json: { error: "UserReading record not found for this user and reading" }, status: :not_found unless @user_reading
  end

  # Params for the legacy create_legacy action, if kept.
  # For the new create, params are derived from current_user and path.
  def user_reading_params
    params.require(:user_reading).permit(:user_id, :reading_id, :completed_on)
  end
end
