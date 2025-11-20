# frozen_string_literal: true

class StatsChallengeSummaryStatistics
  attr_reader :challenge

  def initialize(challenge)
    @challenge = challenge
  end

  def total_chapters_read
    UserReading.joins(:reading).where(readings: { challenge_id: challenge.id }).count
  end

  def number_of_participants
    challenge.users.count
  end

  def chapters_read_today
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    UserReading.joins(:reading)
               .where(readings: { challenge_id: challenge.id, scheduled_date: current_date_in_tz })
               .count
  end

  def first_reader_today
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    today_start = current_date_in_tz.in_time_zone(challenge.timezone).beginning_of_day
    today_end = current_date_in_tz.in_time_zone(challenge.timezone).end_of_day

    first_reading = UserReading.joins(:reading)
                               .where(readings: { challenge_id: challenge.id, scheduled_date: current_date_in_tz })
                               .where("user_readings.created_at >= ? AND user_readings.created_at <= ?", today_start, today_end)
                               .order("user_readings.created_at ASC")
                               .first

    first_reading&.user
  end

  def first_reader_today_time
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    today_start = current_date_in_tz.in_time_zone(challenge.timezone).beginning_of_day
    today_end = current_date_in_tz.in_time_zone(challenge.timezone).end_of_day

    first_reading = UserReading.joins(:reading)
                               .where(readings: { challenge_id: challenge.id, scheduled_date: current_date_in_tz })
                               .where("user_readings.created_at >= ? AND user_readings.created_at <= ?", today_start, today_end)
                               .order("user_readings.created_at ASC")
                               .first

    first_reading&.created_at&.in_time_zone(challenge.timezone)
  end

  def last_10_readers
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    today_start = current_date_in_tz.in_time_zone(challenge.timezone).beginning_of_day
    today_end = current_date_in_tz.in_time_zone(challenge.timezone).end_of_day

    # Get the most recent reading for each unique user for today's scheduled reading completed today
    user_readings = UserReading.joins(:reading, :user)
                               .where(readings: { challenge_id: challenge.id, scheduled_date: current_date_in_tz })
                               .where("user_readings.created_at >= ? AND user_readings.created_at <= ?", today_start, today_end)
                               .select("user_readings.*, MAX(user_readings.created_at) as latest_reading")
                               .group("user_readings.user_id")
                               .order("latest_reading DESC")
                               .limit(10)

    user_readings.map do |user_reading|
      {
        user: user_reading.user,
        time_ago: time_ago_in_words(user_reading.created_at)
      }
    end
  end

  def active_sprint
    @active_sprint ||= challenge.sprints.active.first
  end

  def sprint_progress_percentage
    return 0 unless active_sprint
    return 0 unless active_sprint.begin_date && active_sprint.end_date

    total_days = (active_sprint.end_date - active_sprint.begin_date).to_i + 1
    days_elapsed = [ (Date.current - active_sprint.begin_date).to_i + 1, 0 ].max

    return 100 if days_elapsed >= total_days
    return 0 if days_elapsed <= 0

    ((days_elapsed.to_f / total_days) * 100).round
  end

  def sprint_days_remaining
    return 0 unless active_sprint
    return 0 if active_sprint.end_date < Date.current

    (active_sprint.end_date - Date.current).to_i
  end

  private

  def time_ago_in_words(time)
    seconds_diff = (Time.current - time).to_i

    case seconds_diff
    when 0..59
      "just now"
    when 60..3599
      minutes = seconds_diff / 60
      "#{minutes}m ago"
    when 3600..86399
      hours = seconds_diff / 3600
      "#{hours}h ago"
    when 86400..604799
      days = seconds_diff / 86400
      "#{days}d ago"
    else
      weeks = seconds_diff / 604800
      "#{weeks}w ago"
    end
  end
end
