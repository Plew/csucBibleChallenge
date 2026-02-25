# frozen_string_literal: true

class StatsController < ApplicationController
  CACHE_EXPIRATION = 30.seconds

  def index
    current_challenge = current_user.challenges.first
    @challenge = current_challenge

    @challenge_summary_stats = cached_challenge_summary_stats(current_challenge)
    @personal_stats = cached_personal_stats(current_challenge)
    @current_sprint = cached_current_sprint(current_challenge)
    @sprint_stats = cached_sprint_stats(current_challenge, @current_sprint)
    @challenge_graph_data = cached_challenge_graph_data(current_challenge)
    @sprint_graph_data = cached_sprint_graph_data(current_challenge, @current_sprint)
    @top_readers_data = cached_top_readers(current_challenge)
    @participant_count = cached_participant_count(current_challenge)
    @top_groups_data = cached_top_groups(current_challenge)
    @seven_day_leaderboard_data = cached_seven_day_window(current_challenge)
    @most_liked_verse = cached_most_liked_verse(current_challenge)
    @most_liked_verse_today = calculate_most_liked_verse_today(current_challenge, current_user)
  end

  def challenge
    current_challenge = current_user.challenges.first
    @top_readers_data = cached_top_readers(current_challenge)
    @participant_count = cached_participant_count(current_challenge)
  end

  def group
    current_challenge = current_user.challenges.first
    @top_groups_data = cached_top_groups(current_challenge)
  end

  def personal
  end

  def seven_day_window
    current_challenge = current_user.challenges.first
    @seven_day_leaderboard_data = cached_seven_day_window(current_challenge)
  end

  private

  def cached_top_readers(challenge)
    return [] unless challenge

    cache_key = "stats/top_readers/#{challenge.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      TopReadersStatistics.call(challenge: challenge)
    end
  end

  def cached_participant_count(challenge)
    return 0 unless challenge

    Rails.cache.fetch("stats/participant_count/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      challenge.users.count
    end
  end

  def cached_top_groups(challenge)
    return [] unless challenge

    cache_key = "stats/top_groups/#{challenge.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      TopGroupsStatistics.call(challenge: challenge)
    end
  end

  def cached_seven_day_window(challenge)
    return [] unless challenge

    Rails.cache.fetch("stats/seven_day_window/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      SevenDayWindowStatistics.call(challenge: challenge)
    end
  end

  def cached_most_liked_verse(challenge)
    return nil unless challenge

    Rails.cache.fetch("stats/most_liked_verse/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      calculate_most_liked_verse(challenge)
    end
  end

  def calculate_most_liked_verse(challenge)
    # Find the most liked verse across all readings in this challenge
    reading_ids = challenge.readings.pluck(:id)
    return nil if reading_ids.empty?

    # Group by reading_id and verse_number, count likes, order by count descending
    most_liked = VerseLike
      .where(reading_id: reading_ids)
      .group(:reading_id, :verse_number)
      .order("count_all DESC")
      .limit(1)
      .count
      .first

    return nil unless most_liked

    (reading_id, verse_number), like_count = most_liked
    reading = Reading.find(reading_id)

    # Get the verse text (using KJV as default, or we could use any available version)
    verse = Verse.find_by(
      book_number: reading.book_number,
      chapter_number: reading.chapter_number,
      verse_number: verse_number,
      version: "KJV"
    )

    return nil unless verse

    book_name = helpers.book_number_to_name(reading.book_number)

    {
      reference: "#{book_name} #{reading.chapter_number}:#{verse_number}",
      text: verse.verse_text,
      like_count: like_count
    }
  end

  def calculate_most_liked_verse_today(challenge, user)
    return [] unless challenge

    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    reading_ids = challenge.readings.where(scheduled_date: current_date_in_tz).pluck(:id)
    return [] if reading_ids.empty?

    top_liked = VerseLike
      .where(reading_id: reading_ids)
      .group(:reading_id, :verse_number)
      .order("count_all DESC")
      .limit(5)
      .count

    return [] if top_liked.empty?

    version = user.version.presence || "KJV"
    readings_cache = Reading.where(id: reading_ids).index_by(&:id)

    # Build lookup keys for all needed verses: [book_number, chapter_number, verse_number]
    verse_coords = top_liked.filter_map do |(reading_id, verse_number), _|
      reading = readings_cache[reading_id]
      next unless reading
      [ reading.book_number, reading.chapter_number, verse_number ]
    end

    # Fetch all verses in two queries (preferred version + KJV fallback)
    preferred_verses = Verse.where(version: version).where(verse_coords.map { |b, c, v|
      Verse.sanitize_sql_array([ "(book_number = ? AND chapter_number = ? AND verse_number = ?)", b, c, v ])
    }.join(" OR ")).index_by { |v| [ v.book_number, v.chapter_number, v.verse_number ] }

    fallback_needed = verse_coords.reject { |key| preferred_verses.key?(key) }
    fallback_verses = if fallback_needed.any? && version != "KJV"
      Verse.where(version: "KJV").where(fallback_needed.map { |b, c, v|
        Verse.sanitize_sql_array([ "(book_number = ? AND chapter_number = ? AND verse_number = ?)", b, c, v ])
      }.join(" OR ")).index_by { |v| [ v.book_number, v.chapter_number, v.verse_number ] }
    else
      {}
    end

    top_liked.filter_map do |(reading_id, verse_number), like_count|
      reading = readings_cache[reading_id]
      next unless reading

      key = [ reading.book_number, reading.chapter_number, verse_number ]
      verse = preferred_verses[key] || fallback_verses[key]
      next unless verse

      book_name = helpers.book_number_to_name(reading.book_number)

      {
        reference: "#{book_name} #{reading.chapter_number}:#{verse_number}",
        text: verse.verse_text,
        like_count: like_count,
        version: verse.version
      }
    end
  end

  def cached_challenge_summary_stats(challenge)
    return nil unless challenge

    Rails.cache.fetch("stats/challenge_summary/#{challenge.id}", expires_in: CACHE_EXPIRATION) do
      StatsChallengeSummaryStatistics.new(challenge)
    end
  end

  def cached_personal_stats(challenge)
    return {} unless challenge

    cache_key = "stats/personal/#{current_user.id}/#{challenge.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      calculate_personal_stats(current_user, challenge)
    end
  end

  def calculate_personal_stats(user, challenge)
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    scheduled_query = challenge.readings.where("scheduled_date <= ?", current_date_in_tz)
    scheduled_count = scheduled_query.count

    completed_query = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: challenge.id })
                         .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_count = completed_query.count

    if scheduled_count.zero?
      completion_percentage = 0
    elsif completed_count == scheduled_count
      completion_percentage = 100
    else
      completion_percentage = (completed_count.to_f / scheduled_count * 100).floor
    end

    # Calculate on-schedule percentage
    completed_readings = user.user_readings
                            .joins(:reading)
                            .where(readings: { challenge_id: challenge.id })
                            .where("readings.scheduled_date <= ?", current_date_in_tz)

    on_schedule_count = completed_readings
                       .where("date(user_readings.created_at) <= readings.scheduled_date")
                       .count

    if completed_count.zero?
      on_schedule_percentage = 0
    elsif on_schedule_count == completed_count
      on_schedule_percentage = 100
    else
      on_schedule_percentage = (on_schedule_count.to_f / completed_count * 100).floor
    end

    {
      chapters_completed: completed_count,
      chapters_scheduled: scheduled_count,
      completion_percentage: completion_percentage,
      on_schedule_percentage: on_schedule_percentage
    }
  end

  def cached_current_sprint(challenge)
    return nil unless challenge

    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    Rails.cache.fetch("stats/current_sprint/#{challenge.id}/#{current_date_in_tz}", expires_in: CACHE_EXPIRATION) do
      challenge.sprints.find_by("begin_date <= ? AND end_date >= ?", current_date_in_tz, current_date_in_tz)
    end
  end

  def cached_sprint_stats(challenge, sprint)
    return nil unless challenge && sprint

    cache_key = "stats/sprint_personal/#{current_user.id}/#{challenge.id}/#{sprint.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      calculate_sprint_stats(current_user, challenge, sprint)
    end
  end

  def calculate_sprint_stats(user, challenge, sprint)
    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date

    # Only count readings within the sprint date range that are also scheduled up to today
    scheduled_query = challenge.readings
                              .where("scheduled_date >= ? AND scheduled_date <= ?", sprint.begin_date, sprint.end_date)
                              .where("scheduled_date <= ?", current_date_in_tz)
    scheduled_count = scheduled_query.count

    completed_query = user.user_readings
                         .joins(:reading)
                         .where(readings: { challenge_id: challenge.id })
                         .where("readings.scheduled_date >= ? AND readings.scheduled_date <= ?", sprint.begin_date, sprint.end_date)
                         .where("readings.scheduled_date <= ?", current_date_in_tz)
    completed_count = completed_query.count

    if scheduled_count.zero?
      completion_percentage = 0
    elsif completed_count == scheduled_count
      completion_percentage = 100
    else
      completion_percentage = (completed_count.to_f / scheduled_count * 100).floor
    end

    # Calculate on-schedule percentage for sprint readings
    on_schedule_count = completed_query
                       .where("date(user_readings.created_at) <= readings.scheduled_date")
                       .count

    if completed_count.zero?
      on_schedule_percentage = 0
    elsif on_schedule_count == completed_count
      on_schedule_percentage = 100
    else
      on_schedule_percentage = (on_schedule_count.to_f / completed_count * 100).floor
    end

    {
      chapters_completed: completed_count,
      chapters_scheduled: scheduled_count,
      completion_percentage: completion_percentage,
      on_schedule_percentage: on_schedule_percentage
    }
  end

  def cached_challenge_graph_data(challenge)
    return nil unless challenge

    cache_key = "stats/challenge_graph/#{current_user.id}/#{challenge.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      calculate_challenge_graph_data(current_user, challenge)
    end
  end

  def calculate_challenge_graph_data(user, challenge)
    challenge_readings = challenge.readings.select(:id, :scheduled_date).index_by(&:id)
    total_days = challenge_readings.count

    # Get completed readings with their completion dates
    completed_readings = user.user_readings
      .where(reading_id: challenge_readings.keys)
      .pluck(:reading_id, :completed_on)

    # For each completed reading, determine day number and if it was on time
    completed_days = completed_readings.map do |reading_id, completed_on|
      reading = challenge_readings[reading_id]
      day_number = (reading.scheduled_date - challenge.start_date).to_i
      on_time = (completed_on == reading.scheduled_date)

      { day: day_number, on_time: on_time }
    end

    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    current_day = (current_date_in_tz - challenge.start_date).to_i

    {
      total_days: total_days,
      completed_days: completed_days,
      start_date: challenge.start_date,
      current_day: current_day
    }
  end

  def cached_sprint_graph_data(challenge, sprint)
    return nil unless challenge && sprint

    cache_key = "stats/sprint_graph/#{current_user.id}/#{challenge.id}/#{sprint.id}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
      calculate_sprint_graph_data(current_user, challenge, sprint)
    end
  end

  def calculate_sprint_graph_data(user, challenge, sprint)
    # Get readings within the sprint date range
    sprint_readings = challenge.readings
      .where("scheduled_date >= ? AND scheduled_date <= ?", sprint.begin_date, sprint.end_date)
      .select(:id, :scheduled_date)
      .index_by(&:id)

    total_days = sprint_readings.count

    # Get completed readings within the sprint
    completed_readings = user.user_readings
      .where(reading_id: sprint_readings.keys)
      .pluck(:reading_id, :completed_on)

    # For each completed reading, determine day number (relative to sprint start) and if it was on time
    completed_days = completed_readings.map do |reading_id, completed_on|
      reading = sprint_readings[reading_id]
      day_number = (reading.scheduled_date - sprint.begin_date).to_i
      on_time = (completed_on == reading.scheduled_date)

      { day: day_number, on_time: on_time }
    end

    current_date_in_tz = Time.current.in_time_zone(challenge.timezone).to_date
    current_day = (current_date_in_tz - sprint.begin_date).to_i

    {
      total_days: total_days,
      completed_days: completed_days,
      start_date: sprint.begin_date,
      current_day: current_day
    }
  end
end
