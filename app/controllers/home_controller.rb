class HomeController < ApplicationController
  # GET /
  def index
    # Load public challenges for everyone
    @challenges = Challenge.where("end_date >= ? AND hidden = ?", Date.current, false)

    # Load enrolled challenges for logged-in users
    if logged_in?
      @my_challenges = current_user.challenges.where("end_date >= ?", Date.current)
    end
  end

  # GET /reading
  def reading
    if !logged_in?
      redirect_to challenges_path and return
    end

    # 1. Look for a specific challenge ID in the URL
    if params[:challenge_id].present?
      found = current_user.challenges.find_by(id: params[:challenge_id])
      if found
        set_active_challenge(found)
        @user_challenge = found
      end
    end

    # 2. Fallback to the active challenge
    @user_challenge ||= current_active_challenge

    if !@user_challenge
      redirect_to root_path, notice: "Please join a challenge to start reading!" and return
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

      @selected_readings = @user_challenge.readings.where(scheduled_date: @selected_date).order(:book_number, :chapter_number)

      if @selected_readings.any?
        # Determine which chapter to display: explicit param, or first uncompleted, or first
        if params[:reading_id].present?
          @selected_reading = @selected_readings.find_by(id: params[:reading_id])
        end
        @selected_reading ||= @selected_readings.find { |r| !current_user.user_readings.exists?(reading_id: r.id) } || @selected_readings.first

        @selected_reading_title = helpers.book_number_to_name(@selected_reading.book_number) + " " + @selected_reading.chapter_number.to_s
        user_version = current_user.version || "KJV"
        @reading_is_completed = current_user.user_readings.exists?(reading_id: @selected_reading.id)

        # Prepare verses with reading_id and message counts for interactive display
        verses = VerseFetcher.fetch(
          version: user_version,
          book_number: @selected_reading.book_number,
          chapter_number: @selected_reading.chapter_number
        )

        # Pre-fetch like counts and user likes for all verses in this reading
        like_counts = VerseLike.where(reading_id: @selected_reading.id)
                               .group(:verse_number)
                               .count
        user_liked_verses = VerseLike.where(reading_id: @selected_reading.id, user: current_user)
                                     .pluck(:verse_number)
                                     .to_set

        # Pre-fetch likers for all verses
        likers_by_verse = VerseLike.where(reading_id: @selected_reading.id)
                                   .includes(user: [ :avatar_attachment, :avatar_blob ])
                                   .group_by(&:verse_number)
                                   .transform_values { |likes| likes.map(&:user) }

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
            liked: user_liked_verses.include?(v.verse_number),
            likers: likers_by_verse[v.verse_number] || []
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
      day_readings = challenge.readings.where(scheduled_date: date)
      has_reading = day_readings.exists?
      completed = has_reading && day_readings.all? { |r| user.user_readings.exists?(reading_id: r.id) }
      partial_completed = has_reading && !completed && day_readings.any? { |r| user.user_readings.exists?(reading_id: r.id) }

      # Calculate group completion percentage
      group_completion = 0
      if has_reading
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
        partial_completed: partial_completed,
        group_completion: group_completion,
        has_reading: has_reading,
        readings_count: day_readings.count
      }
    end
  end
end
