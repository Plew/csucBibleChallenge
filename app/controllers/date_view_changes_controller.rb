class DateViewChangesController < ApplicationController

  def create
    cookies[:active_date] = params[:active_date]
    redirect_to dashboard_path
  end

end