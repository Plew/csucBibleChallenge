class UserReadingsController < ApplicationController
  before_action :require_login

  def create
    @reading = Reading.find(params[:reading_id])
    challenge = @reading.challenge

    unless challenge&.timezone.present?
      flash[:alert] = "Challenge timezone not set for this reading."
      redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
      return
    end

    current_date_in_challenge_tz = Time.current.in_time_zone(challenge.timezone).to_date
    scheduled_date = @reading.scheduled_date

    if current_date_in_challenge_tz < scheduled_date
      flash[:alert] = "Cannot mark readings for future dates. This reading is scheduled for #{scheduled_date}."
      redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
      return
    end

    @user_reading = current_user.user_readings.build(reading: @reading, completed_on: current_date_in_challenge_tz)

    if @user_reading.save
      # flash[:notice] = "Marked as read."
    else
      # Handle potential errors, e.g., already marked as read
      flash[:alert] = @user_reading.errors.full_messages.to_sentence.presence || "Could not mark as read."
    end

    # Preserve the selected date when redirecting
    redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
  end
end
