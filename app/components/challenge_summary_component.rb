class ChallengeSummaryComponent < ViewComponent::Base
  def initialize(challenge:)
    @challenge = challenge
    @statistics = challenge.is_a?(Challenge) ? ChallengeStatistics.new(challenge) : MockStatistics.new(challenge)
  end

  private

  attr_reader :challenge, :statistics

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

  def created_at_formatted
    challenge.created_at.strftime("%b %d, %Y")
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
  end
end
