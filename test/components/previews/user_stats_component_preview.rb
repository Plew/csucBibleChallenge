# frozen_string_literal: true

class UserStatsComponentPreview < ViewComponent::Preview
  # User with high completion and on track
  def high_performer
    render(UserStatsComponent.new(user: high_performing_user, challenge: sample_challenge))
  end

  # User with moderate progress but behind schedule
  def moderate_performer
    render(UserStatsComponent.new(user: moderate_performing_user, challenge: sample_challenge))
  end

  # User just starting out
  def new_user
    render(UserStatsComponent.new(user: new_user_with_no_progress, challenge: sample_challenge))
  end

  # User with long streak
  def streak_champion
    render(UserStatsComponent.new(user: streak_champion_user, challenge: sample_challenge))
  end

  private

  def sample_challenge
    challenge = Challenge.new(
      id: 1,
      name: "30-Day Reading Challenge",
      start_date: 30.days.ago.to_date,
      end_date: 30.days.from_now.to_date,
      timezone: 'UTC'
    )
    
    # Mock the readings association with a simple object
    readings = (0..59).map do |day_offset|
      Reading.new(
        id: day_offset + 1,
        challenge_id: 1,
        scheduled_date: 30.days.ago.to_date + day_offset.days,
        book_number: 1,
        chapter_number: day_offset + 1
      )
    end
    
    # Create a simple mock object that responds to the methods we need
    readings_relation = MockReadingsRelation.new(readings)
    
    challenge.define_singleton_method(:readings) do
      readings_relation
    end
    
    challenge
  end

  def high_performing_user
    user = User.new(id: 1, username: "alice", email: "alice@example.com")
    
    # Mock 45 completed readings (75% of 60 total)
    user_readings = (0..44).map do |i|
      UserReading.new(
        id: i + 1,
        user_id: 1,
        reading_id: i + 1,
        completed_on: (30.days.ago.to_date + i.days)
      )
    end
    
    user_readings_relation = MockUserReadingsRelation.new(user_readings, 45)
    
    user.define_singleton_method(:user_readings) do
      user_readings_relation
    end
    
    user
  end

  def moderate_performing_user
    user = User.new(id: 2, username: "bob", email: "bob@example.com")
    
    # Mock 20 completed readings (33% of 60 total) with gaps
    user_readings_relation = MockUserReadingsRelation.new([], 20, 
      (0..19).map { |i| 30.days.ago.to_date + (i * 2).days }
    )
    
    user.define_singleton_method(:user_readings) do
      user_readings_relation
    end
    
    user
  end

  def new_user_with_no_progress
    user = User.new(id: 3, username: "charlie", email: "charlie@example.com")
    
    user_readings_relation = MockUserReadingsRelation.new([], 0, [])
    
    user.define_singleton_method(:user_readings) do
      user_readings_relation
    end
    
    user
  end

  def streak_champion_user
    user = User.new(id: 4, username: "diana", email: "diana@example.com")
    
    # Mock 14-day current streak
    streak_dates = (0..13).map { |i| Date.current - i.days }.reverse
    
    user_readings_relation = MockUserReadingsRelation.new([], 25, streak_dates)
    
    user.define_singleton_method(:user_readings) do
      user_readings_relation
    end
    
    user
  end

  # Simple mock objects to replace RSpec doubles
  class MockReadingsRelation
    def initialize(readings)
      @readings = readings
    end

    def count
      @readings.length
    end

    def any?
      @readings.any?
    end

    def where(*args)
      # Handle different where patterns:
      # .where('scheduled_date <= ?', date) 
      # .where(readings: { challenge_id: id })
      if args.length == 2 && args[0].is_a?(String) && args[0].include?('scheduled_date')
        date_value = args[1]
        filtered = @readings.select { |r| r.scheduled_date <= date_value }
        MockReadingsRelation.new(filtered)
      else
        self
      end
    end
  end

  class MockUserReadingsRelation
    def initialize(user_readings, count = nil, pluck_dates = nil)
      @user_readings = user_readings
      @count = count || user_readings.length
      @pluck_dates = pluck_dates || []
    end

    def joins(association)
      self
    end

    def where(*args)
      # Handle different where call patterns - just return self for mocking
      self
    end

    def count
      @count
    end

    def pluck(column)
      @pluck_dates
    end
  end
end