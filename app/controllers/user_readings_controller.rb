class UserReadingsController < ApplicationController
  before_action :require_login

  def create
    @reading = Reading.find(params[:reading_id])
    @user_reading = current_user.user_readings.build(reading: @reading, completed_on: Date.today)

    if @user_reading.save
      # flash[:notice] = "Marked as read."
    else
      # Handle potential errors, e.g., already marked as read
      flash[:alert] = @user_reading.errors.full_messages.to_sentence.presence || "Could not mark as read."
    end
    redirect_to root_path
  end
end 