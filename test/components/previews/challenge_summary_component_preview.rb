class ChallengeSummaryComponentPreview < ViewComponent::Preview
  def default
    render ChallengeSummaryComponent.new(challenge: sample_challenge)
  end

  def upcoming_challenge
    render ChallengeSummaryComponent.new(challenge: sample_upcoming_challenge)
  end

  def completed_challenge
    render ChallengeSummaryComponent.new(challenge: sample_completed_challenge)
  end

  def active_challenge_with_participants
    render ChallengeSummaryComponent.new(challenge: sample_active_challenge_with_data)
  end

  def long_title_challenge
    render ChallengeSummaryComponent.new(challenge: sample_long_title_challenge)
  end

  private

  def sample_challenge
    # Create a mock challenge using OpenStruct for simplicity
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

  def sample_long_title_challenge
    OpenStruct.new(
      id: 5,
      name: "The Complete Journey Through Every Single Book of the New Testament with Daily Reflections and Commentary Study Challenge",
      start_date: Date.current - 10.days,
      end_date: Date.current + 260.days,
      timezone: "America/Los_Angeles",
      created_at: 1.month.ago,
      readings: OpenStruct.new(count: 270)
    )
  end
end