class DashboardController < ApplicationController
  def show
    @active_date = Current.browser_date
    @checked = CheckIn.for_user_and_date?(current_user, Current.browser_date)
    @recent_user_checkins = CheckIn.recent_with_usernames
  end

  def home
    cookies[:browser_date] = Current.browser_date
    redirect_to dashboard_path
  end

end