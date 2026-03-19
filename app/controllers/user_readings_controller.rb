class UserReadingsController < ApplicationController
  include ReadingDateValidation
  before_action :require_login

  def create
    @reading = Reading.find(params[:reading_id])
    challenge = @reading.challenge

    unless challenge&.timezone.present?
      flash[:alert] = "Challenge timezone not set for this reading."
      redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
      return
    end

    scheduled_date = @reading.scheduled_date
    completed_on = resolve_completed_on(scheduled_date, challenge)

    @user_reading = current_user.user_readings.build(reading: @reading, completed_on: completed_on)

    if @user_reading.save
      CheckBadgesJob.perform_later(current_user.id, challenge.id)
    else
      # Handle potential errors, e.g., already marked as read
      flash[:alert] = @user_reading.errors.full_messages.to_sentence.presence || "Could not mark as read."
    end

    # Preserve the selected date when redirecting
    redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
  rescue ReadingDateValidation::FutureReadingError => e
    flash[:alert] = e.message
    redirect_to params[:date].present? ? root_path(date: params[:date]) : root_path
  end
end
