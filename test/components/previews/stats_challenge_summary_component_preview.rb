# frozen_string_literal: true

class StatsChallengeSummaryComponentPreview < ViewComponent::Preview
  def default
    render StatsChallengeSummaryComponent.new(challenge: sample_challenge)
  end

  def upcoming_challenge
    render StatsChallengeSummaryComponent.new(challenge: sample_upcoming_challenge)
  end

  def completed_challenge
    render StatsChallengeSummaryComponent.new(challenge: sample_completed_challenge)
  end

  def active_challenge_with_high_activity
    render StatsChallengeSummaryComponent.new(challenge: sample_active_challenge_with_data)
  end

  def active_challenge_no_readers_today
    render StatsChallengeSummaryComponent.new(
      challenge: sample_no_readers_challenge,
      statistics: no_readers_statistics
    )
  end

  private

  def sample_challenge
    OpenStruct.new(
      id: 1,
      name: "Through the Bible in a Year",
      start_date: Date.current - 30.days,
      end_date: Date.current + 335.days,
      timezone: "America/New_York",
      created_at: 2.months.ago,
      readings: OpenStruct.new(count: 365)
    )
  end

  def sample_upcoming_challenge
    OpenStruct.new(
      id: 2,
      name: "Psalms & Proverbs Study",
      start_date: Date.current + 10.days,
      end_date: Date.current + 70.days,
      timezone: "America/Los_Angeles",
      created_at: 1.week.ago,
      readings: OpenStruct.new(count: 60)
    )
  end

  def sample_completed_challenge
    OpenStruct.new(
      id: 3,
      name: "Gospel Journey",
      start_date: Date.current - 90.days,
      end_date: Date.current - 1.day,
      timezone: "UTC",
      created_at: 4.months.ago,
      readings: OpenStruct.new(count: 89)
    )
  end

  def sample_active_challenge_with_data
    OpenStruct.new(
      id: 4,
      name: "Romans Deep Dive",
      start_date: Date.current - 5.days,
      end_date: Date.current + 25.days,
      timezone: "America/Chicago",
      created_at: 3.weeks.ago,
      readings: OpenStruct.new(count: 30)
    )
  end

  def sample_no_readers_challenge
    OpenStruct.new(
      id: 5,
      name: "New Challenge - Just Started",
      start_date: Date.current - 1.day,
      end_date: Date.current + 29.days,
      timezone: "America/New_York",
      created_at: 2.days.ago,
      readings: OpenStruct.new(count: 30)
    )
  end

  def no_readers_statistics
    stats = OpenStruct.new(
      number_of_participants: 5,
      total_chapters_read: 12,
      chapters_read_today: 0,
      first_reader_today: nil,
      first_reader_today_time: nil,
      last_10_readers: []
    )
  end
end
