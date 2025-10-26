# frozen_string_literal: true

class ReadingHistoryGraphComponentPreview < ViewComponent::Preview
  # @param total_days number
  # @param completion_percentage number
  def default(total_days: 30, completion_percentage: 50)
    # Generate random completed days based on percentage
    num_completed = (total_days * completion_percentage / 100.0).round
    completed_days = (0...total_days).to_a.sample(num_completed).sort

    render(ReadingHistoryGraphComponent.new(
      total_days: total_days,
      completed_days: completed_days,
      start_date: Date.today - total_days.days
    ))
  end

  # One week challenge with 100% completion
  def one_week_perfect
    render(ReadingHistoryGraphComponent.new(
      total_days: 7,
      completed_days: (0..6).to_a,
      start_date: Date.today - 7.days
    ))
  end

  # One week challenge with partial completion
  def one_week_partial
    render(ReadingHistoryGraphComponent.new(
      total_days: 7,
      completed_days: [0, 2, 4, 6],
      start_date: Date.today - 7.days
    ))
  end

  # 30 day challenge with high completion
  def thirty_days_high
    # Complete first 3 weeks, skip some days in week 4
    completed = (0..20).to_a + [22, 24, 26, 28]

    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: completed,
      start_date: Date.today - 30.days
    ))
  end

  # 30 day challenge with low completion
  def thirty_days_low
    # Complete only a few scattered days
    completed = [0, 1, 5, 8, 12, 15, 20, 22, 28]

    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: completed,
      start_date: Date.today - 30.days
    ))
  end

  # 60 day challenge with streaks
  def sixty_days_streaks
    # Create some streaks with gaps
    completed = (0..9).to_a + (15..24).to_a + (30..44).to_a + [50, 52, 54, 56, 58]

    render(ReadingHistoryGraphComponent.new(
      total_days: 60,
      completed_days: completed,
      start_date: Date.today - 60.days
    ))
  end

  # 90 day challenge (like GitHub annual view)
  def ninety_days
    # Random but realistic pattern
    completed = []
    60.times do
      day = rand(0...90)
      completed << day unless completed.include?(day)
    end

    render(ReadingHistoryGraphComponent.new(
      total_days: 90,
      completed_days: completed.sort,
      start_date: Date.today - 90.days
    ))
  end

  # Empty state - no completion yet
  def empty_state
    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: [],
      start_date: Date.today
    ))
  end

  # Just started - only first day completed
  def just_started
    render(ReadingHistoryGraphComponent.new(
      total_days: 30,
      completed_days: [0],
      start_date: Date.today
    ))
  end
end
