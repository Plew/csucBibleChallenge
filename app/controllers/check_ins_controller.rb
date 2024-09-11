class CheckInsController < ApplicationController
  def create
    toggle
    redirect_to dashboard_path(
      day_offset: params[:day_offset]),
      recorded_on: params[:recorded_on],
      foo: 'bar'
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