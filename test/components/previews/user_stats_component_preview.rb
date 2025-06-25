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
    
    # Mock the readings association
    readings = (0..59).map do |day_offset|
      Reading.new(
        id: day_offset + 1,
        challenge_id: 1,
        scheduled_date: 30.days.ago.to_date + day_offset.days,
        book_number: 1,
        chapter_number: day_offset + 1
      )
    end
    
    challenge.define_singleton_method(:readings) do
      readings_relation = double('readings_relation')
      allow(readings_relation).to receive(:count).and_return(60)
      allow(readings_relation).to receive(:any?).and_return(true)
      allow(readings_relation).to receive(:where) { |condition|
        filtered = readings.select { |r| r.scheduled_date <= Date.current }
        filtered_relation = double('filtered_relation')
        allow(filtered_relation).to receive(:count).and_return(filtered.length)
        filtered_relation
      }
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
    
    user.define_singleton_method(:user_readings) do
      relation = double('user_readings_relation')
      allow(relation).to receive(:joins).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:count).and_return(45)
      allow(relation).to receive(:pluck).and_return(
        (0..44).map { |i| 30.days.ago.to_date + i.days }
      )
      relation
    end
    
    user
  end

  def moderate_performing_user
    user = User.new(id: 2, username: "bob", email: "bob@example.com")
    
    # Mock 20 completed readings (33% of 60 total) with gaps
    user.define_singleton_method(:user_readings) do
      relation = double('user_readings_relation')
      allow(relation).to receive(:joins).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:count).and_return(20)
      allow(relation).to receive(:pluck).and_return(
        (0..19).map { |i| 30.days.ago.to_date + (i * 2).days } # Every other day
      )
      relation
    end
    
    user
  end

  def new_user_with_no_progress
    user = User.new(id: 3, username: "charlie", email: "charlie@example.com")
    
    user.define_singleton_method(:user_readings) do
      relation = double('user_readings_relation')
      allow(relation).to receive(:joins).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:count).and_return(0)
      allow(relation).to receive(:pluck).and_return([])
      relation
    end
    
    user
  end

  def streak_champion_user
    user = User.new(id: 4, username: "diana", email: "diana@example.com")
    
    # Mock 14-day current streak
    streak_dates = (0..13).map { |i| Date.current - i.days }.reverse
    
    user.define_singleton_method(:user_readings) do
      relation = double('user_readings_relation')
      allow(relation).to receive(:joins).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:count).and_return(25)
      allow(relation).to receive(:pluck).and_return(streak_dates)
      relation
    end
    
    user
  end
end