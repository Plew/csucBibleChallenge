class HomeController < ApplicationController
  before_action :require_login, only: [:index] # Redirect to login if not logged in

  # GET /
  def index
    @user_challenge = current_user.challenges.first # User can only be in one challenge as per user_query
    @challenges = Challenge.all # For listing available challenges if user hasn\'t joined one

    if @user_challenge
      today_in_challenge_tz = Time.current.in_time_zone(@user_challenge.timezone).to_date
      
      # Check if a specific date is requested
      if params[:date].present?
        begin
          @selected_date = Date.parse(params[:date])
        rescue Date::Error
          @selected_date = today_in_challenge_tz
        end
      else
        @selected_date = today_in_challenge_tz
      end

      @selected_reading = @user_challenge.readings.find_by(scheduled_date: @selected_date)
      if @selected_reading
        @selected_reading_title = helpers.book_number_to_name(@selected_reading.book_number) + " " + @selected_reading.chapter_number.to_s
        @selected_reading_verses = @selected_reading.verses.map { |v| { verse_number: v.verse_number, verse_text: v.verse_text } }
      end

      # Weekly Check-in Data
      @weekly_check_in_days = WeeklyCheckInService.new(current_user, @user_challenge).days(today_in_challenge_tz)
    end
    # The placeholder @today_readings is removed.
  end
end 