# frozen_string_literal: true

class DatePickerController < ApplicationController
  before_action :require_login

  def show
    @challenge = Challenge.find(params[:challenge_id])
    @selected_date = parse_date(params[:date])

    render DatePickerComponent.new(
      selected_date: @selected_date,
      challenge: @challenge,
      user: current_user
    ), layout: false
  end

  private

  def parse_date(date_string)
    Date.parse(date_string)
  rescue Date::Error, ArgumentError, TypeError
    Date.current
  end
end
