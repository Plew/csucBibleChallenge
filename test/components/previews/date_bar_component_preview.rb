# frozen_string_literal: true

class DateBarComponentPreview < ViewComponent::Preview
  def default
    render DateBarComponent.new(
      selected_date: Date.current,
      mobile: true,
      days: generate_week_with_data(Date.current, [ 1, 3, 5 ])
    )
  end

  def all_completed
    render DateBarComponent.new(
      selected_date: Date.current,
      mobile: true,
      days: generate_week_with_data(Date.current, (0..6).to_a)
    )
  end

  def none_completed
    render DateBarComponent.new(
      selected_date: Date.current,
      mobile: true,
      days: generate_week_with_data(Date.current, [])
    )
  end

  def cross_month_week
    # Week that spans across months (e.g., Aug 30 - Sep 5, 2025)
    cross_month_date = Date.new(2025, 9, 1) # Monday Sep 1st
    render DateBarComponent.new(
      selected_date: cross_month_date,
      mobile: true,
      days: generate_week_with_data(cross_month_date, [ 0, 2, 4 ])
    )
  end

  def selected_past_date
    past_date = Date.current - 7.days # Previous week
    render DateBarComponent.new(
      selected_date: past_date,
      mobile: true,
      days: generate_week_with_data(past_date, [ 0, 1, 2, 3, 4 ]) # Weekdays completed
    )
  end

  def selected_future_date
    future_date = Date.current + 7.days # Next week
    render DateBarComponent.new(
      selected_date: future_date,
      mobile: true,
      days: generate_week_with_data(future_date, [])
    )
  end

  def mixed_reading_availability
    render DateBarComponent.new(
      selected_date: Date.current,
      mobile: true,
      days: generate_week_with_mixed_availability(Date.current)
    )
  end

  def desktop_mode
    render DateBarComponent.new(
      selected_date: Date.current,
      mobile: false,
      days: generate_week_with_data(Date.current, [ 1, 3, 5 ])
    )
  end

  def tuesday_selected
    # Show what it looks like when Tuesday is selected
    tuesday = Date.current.beginning_of_week(:monday) + 1.day
    render DateBarComponent.new(
      selected_date: tuesday,
      mobile: true,
      days: generate_week_with_data(tuesday, [ 0, 1, 3 ])
    )
  end

  def weekend_selected
    # Show what it looks like when weekend day is selected
    saturday = Date.current.beginning_of_week(:monday) + 5.days
    render DateBarComponent.new(
      selected_date: saturday,
      mobile: true,
      days: generate_week_with_data(saturday, [ 0, 1, 2, 3, 4, 5 ])
    )
  end

  private

  def generate_week_with_data(selected_date, completed_day_indices = [])
    # Find the Monday of the week containing the selected date
    start_of_week = selected_date.beginning_of_week(:monday)

    7.times.map do |i|
      date = start_of_week + i.days
      {
        date: date,
        day_of_week: date.strftime("%a"),
        day_of_month: date.day.to_s,
        month_day: date.strftime("%b %-d"),
        completed: completed_day_indices.include?(i),
        group_completion: [ 0, 25, 50, 75, 100, 33, 66 ][i % 7],
        has_reading: true
      }
    end
  end

  def generate_week_with_mixed_availability(selected_date)
    # Find the Monday of the week containing the selected date
    start_of_week = selected_date.beginning_of_week(:monday)

    7.times.map do |i|
      date = start_of_week + i.days
      {
        date: date,
        day_of_week: date.strftime("%a"),
        day_of_month: date.day.to_s,
        month_day: date.strftime("%b %-d"),
        completed: [ 1, 3 ].include?(i),
        group_completion: [ 0, 25, 50, 75, 100, 33, 66 ][i % 7],
        has_reading: i < 5 # Monday-Friday have readings, weekend doesn't
      }
    end
  end
end
