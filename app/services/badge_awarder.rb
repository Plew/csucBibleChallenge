# frozen_string_literal: true

class BadgeAwarder
  attr_reader :user, :challenge

  def initialize(user, challenge)
    @user = user
    @challenge = challenge
  end

  def call
    already_earned = user.user_badges.where(challenge: challenge).pluck(:badge_key)
    newly_awarded = []

    BadgeCatalog.all.each do |badge|
      next if already_earned.include?(badge.key)
      next unless earned?(badge)

      begin
        user.user_badges.create!(challenge: challenge, badge_key: badge.key)
        newly_awarded << badge.key
      rescue ActiveRecord::RecordNotUnique
        # Race condition — already awarded by another process
      end
    end

    newly_awarded
  end

  private

  def earned?(badge)
    case badge.check_type
    when :chapters
      chapters_completed >= badge.threshold
    when :streak
      longest_streak >= badge.threshold
    when :on_time_streak
      longest_on_time_streak >= badge.threshold
    when :perfect_record
      perfect_record_days >= badge.threshold
    when :verse_likes
      verse_like_count >= badge.threshold
    when :early_reading
      early_reading_count >= badge.threshold
    when :late_reading
      late_reading_count >= badge.threshold
    when :last_minute
      last_minute_count >= badge.threshold
    when :bulk_reading
      max_readings_in_one_day >= badge.threshold
    when :returned
      longest_gap_days > badge.threshold
    when :lone_wolf
      perfect_record_days >= badge.threshold && !user_in_group?
    when :weekend_warrior
      consecutive_weekend_days >= badge.threshold
    when :catch_up
      late_reading_count_by_date >= badge.threshold
    when :completion_pct
      completion_percentage >= badge.threshold
    when :chatty_chapter
      max_messages_on_one_reading >= badge.threshold
    when :picky_liker
      readings_with_exactly_one_like >= badge.threshold
    when :conversation_starter
      started_conversations_with_replies >= badge.threshold
    else
      false
    end
  end

  def chapters_completed
    @chapters_completed ||= user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .count
  end

  def longest_streak
    @longest_streak ||= UserStatistics.new(user, challenge).longest_streak
  end

  def longest_on_time_streak
    @longest_on_time_streak ||= calculate_longest_on_time_streak
  end

  def perfect_record_days
    @perfect_record_days ||= calculate_perfect_record_days
  end

  def verse_like_count
    @verse_like_count ||= begin
      reading_ids = challenge.readings.pluck(:id)
      user.verse_likes.where(reading_id: reading_ids).count
    end
  end

  def challenge_tz
    @challenge_tz ||= ActiveSupport::TimeZone[challenge.timezone] || Time.zone
  end

  def reading_timestamps_in_tz
    @reading_timestamps_in_tz ||= user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .pluck("user_readings.created_at")
      .map { |t| t.in_time_zone(challenge_tz) }
  end

  def early_reading_count
    @early_reading_count ||= reading_timestamps_in_tz.count { |t| t.hour == 5 }
  end

  def late_reading_count
    @late_reading_count ||= reading_timestamps_in_tz.count do |t|
      (t.hour == 23 && t.min >= 30) || (t.hour == 0 && t.min == 0 && t.sec == 0)
    end
  end

  def last_minute_count
    @last_minute_count ||= reading_timestamps_in_tz.count { |t| t.hour == 23 && t.min == 59 }
  end

  def max_readings_in_one_day
    @max_readings_in_one_day ||= begin
      dates = reading_timestamps_in_tz.map(&:to_date)
      return 0 if dates.empty?
      dates.tally.values.max
    end
  end

  def longest_gap_days
    @longest_gap_days ||= begin
      dates = reading_timestamps_in_tz.map(&:to_date).uniq.sort
      return 0 if dates.size < 2
      dates.each_cons(2).map { |a, b| (b - a).to_i }.max
    end
  end

  def consecutive_weekend_days
    @consecutive_weekend_days ||= begin
      # Get all weekend dates (Sat/Sun) where the user completed a reading
      weekend_dates = reading_timestamps_in_tz
        .map(&:to_date)
        .uniq
        .select { |d| d.saturday? || d.sunday? }
        .sort

      consecutive_streak(weekend_dates)
    end
  end

  def late_reading_count_by_date
    @late_reading_count_by_date ||= user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .where("DATE(user_readings.completed_on) > readings.scheduled_date")
      .count
  end

  def completion_percentage
    @completion_percentage ||= begin
      current_date = Time.current.in_time_zone(challenge.timezone).to_date
      scheduled = challenge.readings.where("scheduled_date <= ?", current_date).count
      return 0 if scheduled.zero?
      (chapters_completed.to_f / scheduled * 100).floor
    end
  end

  def user_in_group?
    return @user_in_group if defined?(@user_in_group)

    challenge_group_ids = challenge.groups.pluck(:id)
    @user_in_group = challenge_group_ids.any? &&
      UserGroupEnrollment.where(user: user, group_id: challenge_group_ids).exists?
  end

  def max_messages_on_one_reading
    @max_messages_on_one_reading ||= begin
      reading_ids = challenge.readings.pluck(:id)
      counts = VerseMessage.where(user: user, reading_id: reading_ids)
        .group(:reading_id).count
      counts.values.max || 0
    end
  end

  def readings_with_exactly_one_like
    @readings_with_exactly_one_like ||= begin
      reading_ids = challenge.readings.pluck(:id)
      counts = user.verse_likes.where(reading_id: reading_ids)
        .group(:reading_id).count
      counts.values.count { |c| c == 1 }
    end
  end

  def started_conversations_with_replies
    @started_conversations_with_replies ||= begin
      reading_ids = challenge.readings.pluck(:id)
      # Find verses where this user left a message
      user_verse_keys = VerseMessage.where(user: user, reading_id: reading_ids)
        .pluck(:reading_id, :verse_number)
        .map { |r, v| [ r, v ] }
        .uniq

      user_verse_keys.count do |reading_id, verse_number|
        total = VerseMessage.where(reading_id: reading_id, verse_number: verse_number).count
        total >= 5
      end
    end
  end

  def calculate_longest_on_time_streak
    # Get dates where reading was completed on its scheduled date, sorted
    on_time_dates = user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .pluck("readings.scheduled_date")
      .uniq
      .sort

    consecutive_streak(on_time_dates)
  end

  def calculate_perfect_record_days
    # Longest consecutive span of days where ALL readings were completed on time
    current_date = Time.current.in_time_zone(challenge.timezone).to_date
    readings_by_date = challenge.readings
      .where("scheduled_date <= ?", current_date)
      .order(:scheduled_date)
      .group_by(&:scheduled_date)

    completed_reading_ids = user.user_readings
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .where("DATE(user_readings.completed_on) = readings.scheduled_date")
      .pluck(:reading_id)
      .to_set

    max_days = 0
    current_run = 0

    readings_by_date.each do |_date, readings|
      if readings.all? { |r| completed_reading_ids.include?(r.id) }
        current_run += 1
        max_days = [ max_days, current_run ].max
      else
        current_run = 0
      end
    end

    max_days
  end

  def consecutive_streak(sorted_dates)
    return 0 if sorted_dates.empty?

    max_streak = 0
    current_streak = 0
    prev_date = nil

    sorted_dates.each do |date|
      if prev_date && date == prev_date + 1.day
        current_streak += 1
      else
        current_streak = 1
      end
      max_streak = [ max_streak, current_streak ].max
      prev_date = date
    end

    max_streak
  end
end
