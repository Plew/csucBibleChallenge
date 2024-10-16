class DashboardController < ApplicationController
  def show
    # this feels wrong.  initial load, shown date and current date are the same.
    @active_date = Current.active_date
    @checked = CheckIn.for_user_and_date?(current_user, @active_date)
  end

  def home
    cookies[:active_date] = Current.current_date
    redirect_to dashboard_path
  end

end