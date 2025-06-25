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
  # Note: This calculates consecutive days from today backwards using a single SQL query
  def by_current_streak
    sql = <<~SQL
      WITH RECURSIVE streak_calc AS (
        -- Base case: Start from current date for each user
        SELECT 
          users.id as user_id,
          users.username,
          '#{current_date_in_challenge_timezone}' as check_date,
          CASE 
            WHEN completed_readings.reading_date = '#{current_date_in_challenge_timezone}' THEN 1 
            ELSE 0 
          END as current_streak,
          0 as iteration
        FROM users
        INNER JOIN user_challenge_enrollments uce ON uce.user_id = users.id AND uce.challenge_id = #{challenge.id}
        LEFT JOIN (
          SELECT ur.user_id, r.scheduled_date as reading_date
          FROM user_readings ur
          INNER JOIN readings r ON r.id = ur.reading_id 
          WHERE r.challenge_id = #{challenge.id} 
            AND r.scheduled_date <= '#{current_date_in_challenge_timezone}'
        ) completed_readings ON completed_readings.user_id = users.id 
                              AND completed_readings.reading_date = '#{current_date_in_challenge_timezone}'
        
        UNION ALL
        
        -- Recursive case: Check previous days
        SELECT 
          sc.user_id,
          u.username,
          date(sc.check_date, '-1 day'),
          CASE 
            WHEN cr.reading_date = date(sc.check_date, '-1 day') AND sc.current_streak > 0 
            THEN sc.current_streak + 1
            ELSE 0
          END,
          sc.iteration + 1
        FROM streak_calc sc
        INNER JOIN users u ON u.id = sc.user_id
        LEFT JOIN (
          SELECT ur.user_id, r.scheduled_date as reading_date
          FROM user_readings ur
          INNER JOIN readings r ON r.id = ur.reading_id 
          WHERE r.challenge_id = #{challenge.id}
            AND r.scheduled_date <= '#{current_date_in_challenge_timezone}'
        ) cr ON cr.user_id = sc.user_id AND cr.reading_date = date(sc.check_date, '-1 day')
        WHERE sc.current_streak > 0 
          AND date(sc.check_date, '-1 day') >= '#{challenge.start_date}'
          AND sc.iteration < 365  -- Prevent infinite recursion
      ),
      user_max_streaks AS (
        SELECT 
          user_id,
          username,
          MAX(current_streak) as current_streak
        FROM streak_calc 
        GROUP BY user_id, username
      )
      SELECT users.*, COALESCE(ums.current_streak, 0) as current_streak
      FROM users
      INNER JOIN user_challenge_enrollments uce ON uce.user_id = users.id AND uce.challenge_id = #{challenge.id}
      LEFT JOIN user_max_streaks ums ON ums.user_id = users.id
      ORDER BY current_streak DESC, users.username ASC
      LIMIT #{limit}
    SQL

    User.find_by_sql(sql).map do |user|
      user.define_singleton_method(:current_streak) { user[:current_streak].to_i }
      user
    end
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

end