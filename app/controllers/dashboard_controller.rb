class DashboardController < ApplicationController
  def show
    # this feels wrong.  initial load, shown date and current date are the same.
    @shown_date = cookies[:current_date] || Date.today.strftime('%Y-%m-%d')
    @current_date = cookies[:current_date] || Date.today.strftime('%Y-%m-%d')
  end
end