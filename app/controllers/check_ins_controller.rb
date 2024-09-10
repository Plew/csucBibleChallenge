class CheckInsController < ApplicationController
  def create
    toggle
    redirect_to dashboard_path(
      recorded_on: params[:recorded_on]
      day_offset: params[:day_offset])
  end

  def toggle
    check_in = CheckIn.find_by(user: current_user, recorded_on: params[:recorded_on])

    if check_in
      check_in.destroy
    else
      CheckIn.create(user: current_user, recorded_on: params[:recorded_on])
    end
  end
end