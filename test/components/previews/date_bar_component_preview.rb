# frozen_string_literal: true

class DateBarComponentPreview < ViewComponent::Preview
  def default
    render DateBarComponent.new(
      days: sample_days,
      selected_date: Date.current,
      mobile: true
    )
  end

  def all_completed
    completed_days = sample_days.map { |day| day.merge(completed: true) }
    render DateBarComponent.new(
      days: completed_days,
      selected_date: Date.current,
      mobile: true
    )
  end

  def none_completed
    incomplete_days = sample_days.map { |day| day.merge(completed: false) }
    render DateBarComponent.new(
      days: incomplete_days,
      selected_date: Date.current,
      mobile: true
    )
  end

  def cross_month_dates
    render DateBarComponent.new(
      days: generate_cross_month_days,
      selected_date: Date.new(2025, 9, 1), # Sept 1st
      mobile: true
    )
  end

  def selected_past_date
    past_date = Date.current - 3.days
    render DateBarComponent.new(
      days: sample_days_for_date(past_date),
      selected_date: past_date,
      mobile: true
    )
  end

  def selected_future_date
    future_date = Date.current + 2.days
    render DateBarComponent.new(
      days: sample_days_for_date(future_date),
      selected_date: future_date,
      mobile: true
    )
  end

  def mixed_reading_availability
    mixed_days = sample_days.map.with_index do |day, index|
      # Every other day has no reading scheduled
      day.merge(has_reading: index.even?)
    end
    render DateBarComponent.new(
      days: mixed_days,
      selected_date: Date.current,
      mobile: true
    )
  end

  def desktop_mode
    render DateBarComponent.new(
      days: sample_days,
      selected_date: Date.current,
      mobile: false
    )
  end

  private

  def sample_days
    today = Date.current
    7.times.map do |i|
      date = today - (6 - i).days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: [1, 3, 5].include?(i), # Some days completed
        group_completion: [0, 25, 50, 75, 100, 33, 66][i],
        has_reading: true
      }
    end
  end

  def sample_days_for_date(target_date)
    7.times.map do |i|
      date = target_date - 3.days + i.days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: date <= Date.current - 1.day, # Past days completed
        group_completion: rand(0..100),
        has_reading: true
      }
    end
  end

  def generate_cross_month_days
    # Generate dates from Aug 29 to Sep 4 (cross month)
    start_date = Date.new(2025, 8, 29)
    7.times.map do |i|
      date = start_date + i.days
      {
        date: date,
        day_of_week: date.strftime('%a'),
        day_of_month: date.day.to_s,
        month_day: date.strftime('%b %-d'),
        completed: i < 3, # First few days completed
        group_completion: [25, 50, 75, 100, 20, 40, 60][i],
        has_reading: true
      }
    end
  end
end