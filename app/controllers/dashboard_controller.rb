class DashboardController < ApplicationController
  def show
    # this feels wrong.  initial load, shown date and current date are the same.
    @shown_date = cookies[:shown_date] || Date.today.strftime('%Y-%m-%d')
    @checked = CheckIn.for_user_and_date?(current_user, @shown_date)
  end
end