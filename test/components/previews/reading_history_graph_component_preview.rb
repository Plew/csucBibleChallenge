# frozen_string_literal: true

class ReadingHistoryGraphComponentPreview < ViewComponent::Preview
  # @param total_days number
  # @param completion_percentage number
  def default(total_days: 30, completion_percentage: 50)
    # Generate random completed days based on percentage
    num_completed = (total_days * completion_percentage / 100.0).round
    # Generate completed days with on_time status
    completed_day_numbers = (0...total_days).to_a.sample(num_completed).sort
    completed_days = completed_day_numbers.map do |day|
      { day: day, on_time: rand < 0.8 } # 80% chance of being on time
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: total_days,
      completed_days: completed_days,
      start_date: Date.today - total_days.days,
      current_day: 15 # Midpoint of the challenge
    ))
  end

  # One week challenge with 100% completion
  def one_week_perfect
    completed_days = (0..6).map { |day| { day: day, on_time: true } }
    render(ReadingHistoryGraphComponent.new(
      total_days: 7,
      completed_days: completed_days,
      start_date: Date.today - 7.days,
      current_day: 6 # Last day
    ))
  end

  # One week challenge with partial completion
  def one_week_partial
    completed_days = [
      { day: 0, on_time: true },
      { day: 2, on_time: true },
      { day: 4, on_time: false }, # Late
      { day: 6, on_time: true }
    ]
    render(ReadingHistoryGraphComponent.new(
      total_days: 7,
      completed_days: completed_days,
      start_date: Date.today - 7.days,
      current_day: 4 # Current day
    ))
  end

  # 30 day challenge with high completion
  def thirty_days_high
    # Complete first 3 weeks, skip some days in week 4
    completed_day_numbers = (0..20).to_a + [ 22, 24, 26, 28 ]
    completed_days = completed_day_numbers.map do |day|
      { day: day, on_time: day < 22 || day.even? } # Some late completions
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: completed_days,
      start_date: Date.today - 30.days,
      current_day: 20
    ))
  end

  # 30 day challenge with low completion
  def thirty_days_low
    # Complete only a few scattered days
    completed_day_numbers = [ 0, 1, 5, 8, 12, 15, 20, 22, 28 ]
    completed_days = completed_day_numbers.map do |day|
      { day: day, on_time: rand < 0.7 } # 70% on time
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: completed_days,
      start_date: Date.today - 30.days,
      current_day: 25
    ))
  end

  # 60 day challenge with streaks
  def sixty_days_streaks
    # Create some streaks with gaps
    completed_day_numbers = (0..9).to_a + (15..24).to_a + (30..44).to_a + [ 50, 52, 54, 56, 58 ]
    completed_days = completed_day_numbers.map do |day|
      { day: day, on_time: rand < 0.85 } # 85% on time
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: 60,
      completed_days: completed_days,
      start_date: Date.today - 60.days,
      current_day: 45
    ))
  end

  # 90 day challenge (like GitHub annual view)
  def ninety_days
    # Random but realistic pattern
    completed_day_numbers = []
    60.times do
      day = rand(0...90)
      completed_day_numbers << day unless completed_day_numbers.include?(day)
    end
    completed_days = completed_day_numbers.sort.map do |day|
      { day: day, on_time: rand < 0.75 } # 75% on time
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: 90,
      completed_days: completed_days,
      start_date: Date.today - 90.days,
      current_day: 60
    ))
  end

  # Empty state - no completion yet
  def empty_state
    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: [],
      start_date: Date.today,
      current_day: 0 # First day
    ))
  end

  # Just started - only first day completed
  def just_started
    completed_days = [ { day: 0, on_time: true } ]
    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: completed_days,
      start_date: Date.today,
      current_day: 1 # Second day
    ))
  end
end
