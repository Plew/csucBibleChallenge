class DateViewChangesController < ApplicationController

    def create
      @shown_date = params[:shown_date]
      @current_date = current_date_string
    end
end