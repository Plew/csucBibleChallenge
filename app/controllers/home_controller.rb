class HomeController < ApplicationController
  # GET /
  def index
    if logged_in?
      user_challenge = current_user.challenges.first

      # If user has a challenge that hasn't started yet, redirect to challenge show page
      if user_challenge && Date.current < user_challenge.start_date
        redirect_to challenge_path(user_challenge) and return
      end

      # Otherwise redirect to reading page, preserving date parameter
      redirect_to reading_path(params.permit(:date)) and return
    end

    # Show welcome screen for logged-out users
    @challenges = Challenge.where("end_date >= ? AND hidden = ?", Date.current, false)
  end

  # GET /reading
  def reading
    # Allow both logged-in and logged-out users to access this page
    if !logged_in?
      # For logged-out users, redirect to challenges page
      redirect_to challenges_path and return
    end

    @user_challenge = current_user.challenges.first # User can only be in one challenge as per user_query

    # If user is not enrolled in any challenge, redirect to challenges page
    if !@user_challenge
      redirect_to challenges_path and return
    end

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
        user_version = current_user.version || "KJV"
        @reading_is_completed = current_user.user_readings.exists?(reading_id: @selected_reading.id)

        # Prepare verses with reading_id and message counts for interactive display
        verses = @selected_reading.verses(version: user_version)

        # Pre-fetch like counts and user likes for all verses in this reading
        like_counts = VerseLike.where(reading_id: @selected_reading.id)
                               .group(:verse_number)
                               .count
        user_liked_verses = VerseLike.where(reading_id: @selected_reading.id, user: current_user)
                                     .pluck(:verse_number)
                                     .to_set

        @selected_reading_verses = verses.map do |v|
          {
            reading_id: @selected_reading.id,
            verse_number: v.verse_number,
            verse_text: v.verse_text,
            messages: VerseMessage.for_verse(@selected_reading.id, v.verse_number)
                                  .includes(user: [ :avatar_attachment, :avatar_blob ])
                                  .order(:created_at)
                                  .limit(50),
            like_count: like_counts[v.verse_number] || 0,
            liked: user_liked_verses.include?(v.verse_number)
          }
        end
      end

      # Calculate previous and next dates for navigation
      @previous_date = @selected_date - 1.day
      @next_date = @selected_date + 1.day

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
        day_of_week: date.strftime("%a"),
        day_of_month: date.day.to_s,
        month_day: date.strftime("%b %-d"),
        completed: completed,
        group_completion: group_completion,
        has_reading: reading.present?
      }
    end
  end
end
