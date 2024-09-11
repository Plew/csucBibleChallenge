class DateViewChangesController < ApplicationController

    def create
      @shown_date = params[:shown_date]
      @current_date = cookies[:current_date]
    end
end