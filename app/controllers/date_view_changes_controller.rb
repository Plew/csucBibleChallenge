class DateViewChangesController < ApplicationController

  def create
    cookies[:shown_date] = params[:shown_date]
    redirect_to dashboard_path
  end

end