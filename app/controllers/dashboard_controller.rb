class DashboardController < ApplicationController
  def show
    @shown_date = cookies[:current_date] || Date.today.strftime('%Y-%m-%d')
  end
end