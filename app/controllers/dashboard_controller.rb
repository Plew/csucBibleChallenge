class DashboardController < ApplicationController
  def show
    @active_date = Current.active_date
    @checked = CheckIn.for_user_and_date?(current_user, @active_date)
    @recent_user_checkins = CheckIn.recent_with_usernames
  end

  def home
    cookies[:active_date] = Current.current_date
    redirect_to dashboard_path
  end

end