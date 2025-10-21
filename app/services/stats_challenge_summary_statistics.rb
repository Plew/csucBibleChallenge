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
               .where(readings: { challenge_id: challenge.id })
               .where('DATE(user_readings.created_at) = ?', current_date_in_tz)
               .count
  end

  def first_reader_today
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    first_reading = UserReading.joins(:reading)
                               .where(readings: { challenge_id: challenge.id })
                               .where('DATE(user_readings.created_at) = ?', current_date_in_tz)
                               .order('user_readings.created_at ASC')
                               .first

    first_reading&.user
  end

  def first_reader_today_time
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    first_reading = UserReading.joins(:reading)
                               .where(readings: { challenge_id: challenge.id })
                               .where('DATE(user_readings.created_at) = ?', current_date_in_tz)
                               .order('user_readings.created_at ASC')
                               .first

    first_reading&.created_at
  end

  def last_10_readers
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    # Get the most recent reading for each unique user today
    user_readings = UserReading.joins(:reading, :user)
                               .where(readings: { challenge_id: challenge.id })
                               .where('DATE(user_readings.created_at) = ?', current_date_in_tz)
                               .select('user_readings.*, MAX(user_readings.created_at) as latest_reading')
                               .group('user_readings.user_id')
                               .order('latest_reading DESC')
                               .limit(10)

    user_readings.map do |user_reading|
      {
        user: user_reading.user,
        time_ago: time_ago_in_words(user_reading.created_at)
      }
    end
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
