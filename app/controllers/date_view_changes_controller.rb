class DateViewChangesController < ApplicationController

  def create
    @shown_date = params[:shown_date]
    @checked = CheckIn.for_user_and_date?(current_user, @shown_date)
  end

end