class DateViewChangesController < ApplicationController

  def create
    cookies[:active_date] = Date.parse params[:active_date]
    redirect_to dashboard_path
  end

end