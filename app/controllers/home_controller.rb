class HomeController < ApplicationController
  before_action :require_login, only: [:index] # Redirect to login if not logged in

  # GET /
  def index
    @user_challenge = current_user.challenges.first # User can only be in one challenge as per user_query
    @challenges = Challenge.where('end_date >= ?', Date.current) # Only show active/future challenges

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

      # Always use mobile mode (7 days maximum)
      @is_mobile = true  # Always assume mobile for consistent UI
      
      # Generate Monday-Sunday week containing the selected date
      start_of_week = @selected_date.beginning_of_week(:monday)
      @weekly_check_in_days = generate_week_days(start_of_week, @user_challenge, current_user)
    end
    # The placeholder @today_readings is removed.
  end

  private

  def generate_week_days(start_of_week, challenge, user)
    7.times.map do |i|
      date = start_of_week + i.days
      reading = challenge.readings.find_by(scheduled_date: date)
      completed = reading && user.user_readings.exists?(reading_id: reading.id)
      
      # Calculate group completion percentage
      group_completion = 0
      if reading
        user_group = user.groups.find_by(challenge_id: challenge.id)
        if user_group
          group_stats = GroupStatistics.new(user_group)
          group_completion = group_stats.check_in_percentage(date).to_i
        end
      end

      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: completed,
        group_completion: group_completion,
        has_reading: reading.present?
      }
    end
  end
end 