# frozen_string_literal: true

class StatsChallengeSummaryComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(challenge:, statistics: nil, most_liked_verse_today: nil)
    @challenge = challenge
    @statistics = statistics || (challenge.is_a?(Challenge) ? StatsChallengeSummaryStatistics.new(challenge) : MockStatistics.new(challenge))
    @most_liked_verse_today = most_liked_verse_today
  end

  private

  attr_reader :challenge, :statistics, :most_liked_verse_today

  def challenge_progress_percentage
    return 0 unless challenge.start_date && challenge.end_date

    total_days = (challenge.end_date - challenge.start_date).to_i + 1
    days_elapsed = [ (Date.current - challenge.start_date).to_i + 1, 0 ].max

    return 100 if days_elapsed >= total_days
    return 0 if days_elapsed <= 0

    ((days_elapsed.to_f / total_days) * 100).floor
  end

  def days_remaining
    return 0 if challenge.end_date < Date.current
    (challenge.end_date - Date.current).to_i
  end

  def days_until_start
    return 0 if challenge.start_date <= Date.current
    (challenge.start_date - Date.current).to_i
  end

  def challenge_status
    current_date = Date.current

    if current_date < challenge.start_date
      "upcoming"
    elsif current_date > challenge.end_date
      "completed"
    else
      "active"
    end
  end

  def status_badge_class
    case challenge_status
    when "upcoming"
      "badge-info"
    when "active"
      "badge-success"
    when "completed"
      "badge-neutral"
    end
  end

  def status_text
    case challenge_status
    when "upcoming"
      "Starts in #{pluralize(days_until_start, 'day')}"
    when "active"
      "#{pluralize(days_remaining, 'day')} remaining in this challenge"
    when "completed"
      "Challenge completed"
    end
  end

  def formatted_start_date
    challenge.start_date.strftime("%b %d, %Y")
  end

  def formatted_end_date
    challenge.end_date.strftime("%b %d, %Y")
  end

  def total_duration_days
    (challenge.end_date - challenge.start_date).to_i + 1
  end

  def sprint_total_days
    return 0 unless statistics.active_sprint
    (statistics.active_sprint.end_date - statistics.active_sprint.begin_date).to_i + 1
  end

  def first_reader_username
    statistics.first_reader_today&.username || "None yet"
  end

  def first_reader_time_formatted
    if statistics.respond_to?(:first_reader_today_time) && statistics.first_reader_today_time
      time = statistics.first_reader_today_time
      formatted_time = time.in_time_zone(challenge.timezone).strftime("%H:%M")
      "(#{formatted_time})"
    else
      ""
    end
  end

  def pluralize(count, singular, plural = nil)
    word = count == 1 ? singular : (plural || "#{singular}s")
    "#{count} #{word}"
  end

  # Mock statistics class for preview/testing
  class MockStatistics
    def initialize(challenge)
      @challenge = challenge
    end

    def active_sprint
      nil  # Return nil by default for mock
    end

    def sprint_progress_percentage
      0
    end

    def sprint_days_remaining
      0
    end

    def number_of_participants
      case @challenge.name
      when "Through the Bible in a Year"
        42
      when "Psalms & Proverbs Study"
        8
      when "Gospel Journey"
        156
      when "Romans Deep Dive"
        23
      else
        10
      end
    end

    def total_chapters_read
      case @challenge.name
      when "Through the Bible in a Year"
        1247
      when "Psalms & Proverbs Study"
        0
      when "Gospel Journey"
        12784
      when "Romans Deep Dive"
        89
      else
        50
      end
    end

    def chapters_read_today
      case @challenge.name
      when "Through the Bible in a Year"
        28
      when "Psalms & Proverbs Study"
        0
      when "Gospel Journey"
        142
      when "Romans Deep Dive"
        15
      else
        5
      end
    end

    def first_reader_today
      OpenStruct.new(
        username: "john_doe",
        avatar: OpenStruct.new(attached?: false)
      )
    end

    def first_reader_today_time
      Time.current - 6.hours
    end

    def last_10_readers
      [
        { user: OpenStruct.new(username: "sarah_smith", avatar: OpenStruct.new(attached?: false)), time_ago: "5m ago" },
        { user: OpenStruct.new(username: "mike_jones", avatar: OpenStruct.new(attached?: false)), time_ago: "12m ago" },
        { user: OpenStruct.new(username: "emma_wilson", avatar: OpenStruct.new(attached?: false)), time_ago: "1h ago" },
        { user: OpenStruct.new(username: "david_brown", avatar: OpenStruct.new(attached?: false)), time_ago: "2h ago" },
        { user: OpenStruct.new(username: "lisa_garcia", avatar: OpenStruct.new(attached?: false)), time_ago: "3h ago" },
        { user: OpenStruct.new(username: "john_doe", avatar: OpenStruct.new(attached?: false)), time_ago: "6h ago" },
        { user: OpenStruct.new(username: "anna_taylor", avatar: OpenStruct.new(attached?: false)), time_ago: "8h ago" },
        { user: OpenStruct.new(username: "chris_martin", avatar: OpenStruct.new(attached?: false)), time_ago: "10h ago" },
        { user: OpenStruct.new(username: "nina_patel", avatar: OpenStruct.new(attached?: false)), time_ago: "1d ago" },
        { user: OpenStruct.new(username: "tom_hardy", avatar: OpenStruct.new(attached?: false)), time_ago: "1d ago" }
      ]
    end
  end
end
