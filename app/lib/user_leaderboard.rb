class UserLeaderboard
  attr_reader :challenge, :limit

  def initialize(challenge, limit: 10)
    @challenge = challenge
    @limit = limit
  end

  # Returns users ordered by overall completion percentage (highest first)
  def by_completion_percentage
    return [] if total_readings.zero?

    sql = <<~SQL
      SELECT users.*, 
             COALESCE(completions.count, 0) as completed_count,
             ROUND(COALESCE(completions.count, 0) * 100.0 / #{total_readings}, 1) as completion_percentage
      FROM users
      INNER JOIN user_challenge_enrollments uce ON uce.user_id = users.id AND uce.challenge_id = #{challenge.id}
      LEFT JOIN (
        SELECT ur.user_id, COUNT(*) as count
        FROM user_readings ur
        INNER JOIN readings r ON r.id = ur.reading_id AND r.challenge_id = #{challenge.id}
        GROUP BY ur.user_id
      ) completions ON completions.user_id = users.id
      ORDER BY completion_percentage DESC, users.username ASC
      LIMIT #{limit}
    SQL

    User.find_by_sql(sql).map do |user|
      user.define_singleton_method(:completed_count) { user[:completed_count].to_i }
      user.define_singleton_method(:completion_percentage) { user[:completion_percentage].to_f }
      user
    end
  end

  # Returns users ordered by on-track percentage (highest first)
  def by_on_track_percentage
    return [] if readings_to_date.zero?

    sql = <<~SQL
      SELECT users.*, 
             COALESCE(completions.count, 0) as completed_to_date_count,
             ROUND(COALESCE(completions.count, 0) * 100.0 / #{readings_to_date}, 1) as on_track_percentage
      FROM users
      INNER JOIN user_challenge_enrollments uce ON uce.user_id = users.id AND uce.challenge_id = #{challenge.id}
      LEFT JOIN (
        SELECT ur.user_id, COUNT(*) as count
        FROM user_readings ur
        INNER JOIN readings r ON r.id = ur.reading_id AND r.challenge_id = #{challenge.id} AND r.scheduled_date <= '#{current_date_in_challenge_timezone}'
        GROUP BY ur.user_id
      ) completions ON completions.user_id = users.id
      ORDER BY on_track_percentage DESC, users.username ASC
      LIMIT #{limit}
    SQL

    User.find_by_sql(sql).map do |user|
      user.define_singleton_method(:completed_to_date_count) { user[:completed_to_date_count].to_i }
      user.define_singleton_method(:on_track_percentage) { user[:on_track_percentage].to_f }
      user
    end
  end

  # Returns users ordered by total reading count (highest first)
  def by_total_readings
    sql = <<~SQL
      SELECT users.*, 
             COALESCE(completions.count, 0) as total_completed
      FROM users
      INNER JOIN user_challenge_enrollments uce ON uce.user_id = users.id AND uce.challenge_id = #{challenge.id}
      LEFT JOIN (
        SELECT ur.user_id, COUNT(*) as count
        FROM user_readings ur
        INNER JOIN readings r ON r.id = ur.reading_id AND r.challenge_id = #{challenge.id}
        GROUP BY ur.user_id
      ) completions ON completions.user_id = users.id
      ORDER BY total_completed DESC, users.username ASC
      LIMIT #{limit}
    SQL

    User.find_by_sql(sql).map do |user|
      user.define_singleton_method(:total_completed) { user[:total_completed].to_i }
      user
    end
  end

  # Returns users ordered by current reading streak (highest first)
  # Note: This is a simplified streak calculation - consecutive days from today backwards
  def by_current_streak
    user_streaks = enrolled_users.map do |user|
      streak_days = calculate_current_streak(user)
      { user: user, streak_days: streak_days }
    end

    user_streaks
      .sort_by { |entry| [-entry[:streak_days], entry[:user].username] }
      .first(limit)
      .map { |entry| entry[:user].tap { |u| u.define_singleton_method(:current_streak) { entry[:streak_days] } } }
  end

  # Returns users ordered by most recent activity (most recent first)
  def by_recent_activity
    enrolled_users
      .joins(user_readings: :reading)
      .where(readings: { challenge_id: challenge.id })
      .group('users.id')
      .select('users.*',
              'MAX(user_readings.completed_on) as last_reading_date',
              "COUNT(CASE WHEN readings.challenge_id = #{challenge.id} THEN 1 END) as total_completed")
      .order('last_reading_date DESC, users.username ASC')
      .limit(limit)
  end

  private

  def enrolled_users
    @enrolled_users ||= User.joins(:user_challenge_enrollments)
                           .where(user_challenge_enrollments: { challenge_id: challenge.id })
  end

  def total_readings
    @total_readings ||= challenge.readings.count
  end

  def readings_to_date
    @readings_to_date ||= challenge.readings
                                  .where('scheduled_date <= ?', current_date_in_challenge_timezone)
                                  .count
  end

  def current_date_in_challenge_timezone
    @current_date ||= Time.current.in_time_zone(challenge.timezone).to_date
  end

  def calculate_current_streak(user)
    return 0 if total_readings.zero?

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