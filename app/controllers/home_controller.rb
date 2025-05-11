class HomeController < ApplicationController
  before_action :require_login, only: [:index] # Redirect to login if not logged in

  # GET /
  def index
    @user_challenge = current_user.challenges.first # User can only be in one challenge as per user_query
    @challenges = Challenge.all # For listing available challenges if user hasn\'t joined one

    if @user_challenge
      today_in_challenge_tz = Time.current.in_time_zone(@user_challenge.timezone).to_date
      @todays_reading = @user_challenge.readings.find_by(scheduled_date: today_in_challenge_tz)
    end
    # The placeholder @today_readings is removed.
  end
end 