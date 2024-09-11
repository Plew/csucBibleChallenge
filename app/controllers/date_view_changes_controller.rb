class DateViewChangesController < ApplicationController

    def create
      @shown_date = params[:shown_date]
      # You might want to add some date validation here
    end
end