# frozen_string_literal: true

class UserStatsComponent < ViewComponent::Base
  def initialize(user:, challenge:)
    @user = user
    @challenge = challenge
    @stats = UserChallengeStats.new(user, challenge)
  end

  private

  attr_reader :user, :challenge, :stats

  def overall_progress_percentage
    stats.completion_percentage
  end

  def overall_progress_description
    total_readings = challenge.readings.count
    completed_count = completed_readings_count
    "#{completed_count} of #{total_readings} readings completed"
  end

  def on_track_percentage
    stats.on_track_percentage
  end

  def on_track_description
    readings_to_date = challenge.readings
                                .where('scheduled_date <= ?', current_date_in_challenge_timezone)
                                .count
    completed_to_date = completed_readings_to_date_count
    "#{completed_to_date} of #{readings_to_date} readings to date"
  end

  def current_streak_days
    # Simple streak calculation for display
    calculate_current_streak
  end

  def streak_description
    days = current_streak_days
    case days
    when 0
      "Start your streak today!"
    when 1
      "🔥 Great start!"
    when 2..6
      "🔥 Keep it up!"
    when 7..13
      "🔥🔥 Amazing streak!"
    else
      "🔥🔥🔥 Incredible dedication!"
    end
  end

  def checkmark_icon_svg
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
    SVG
  end

  def clock_icon_svg
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
    SVG
  end

  def completed_readings_count
    @completed_readings_count ||= user.user_readings
                                     .joins(:reading)
                                     .where(readings: { challenge_id: challenge.id })
                                     .count
  end

  def completed_readings_to_date_count
    @completed_readings_to_date_count ||= user.user_readings
                                             .joins(:reading)
                                             .where(readings: { 
                                               challenge_id: challenge.id,
                                               scheduled_date: ..current_date_in_challenge_timezone 
                                             })
                                             .count
  end

  def current_date_in_challenge_timezone
    @current_date ||= Time.current.in_time_zone(challenge.timezone).to_date
  end

  def calculate_current_streak
    return 0 unless challenge.readings.any?

    # Get all user's completed readings for this challenge, ordered by scheduled date desc
    completed_dates = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: challenge.id })
                         .where('readings.scheduled_date <= ?', current_date_in_challenge_timezone)
                         .pluck('readings.scheduled_date')
                         .sort.reverse

    return 0 if completed_dates.empty?

    # Calculate streak from most recent date backwards
    streak = 0
    current_check_date = current_date_in_challenge_timezone

    # Start from today and work backwards
    while current_check_date >= challenge.start_date
      if completed_dates.include?(current_check_date)
        streak += 1
        current_check_date -= 1.day
      else
        break
      end
    end

    streak
  end
end