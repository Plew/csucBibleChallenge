class DashboardController < ApplicationController
  def show
    @day_offset = params[:day_offset].to_i
    if params[:recorded_on].present?

      date = Date.parse(params[:recorded_on])
      @checked = current_user.check_ins.exists?(recorded_on: date)
    end
  end
end