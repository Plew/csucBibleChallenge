# frozen_string_literal: true

class DateCircleComponentPreview < ViewComponent::Preview
  def default
    render DateCircleComponent.new(
      date: Date.current,
      day_of_week: Date.current.strftime('%a'),
      month_day: Date.current.strftime('%b %-d'),
      completed: false,
      selected: false,
      has_reading: true
    )
  end

  def selected_not_completed
    today = Date.current
    render DateCircleComponent.new(
      date: today,
      day_of_week: today.strftime('%a'),
      month_day: today.strftime('%b %-d'),
      completed: false,
      selected: true,
      has_reading: true
    )
  end

  def completed_not_selected
    yesterday = Date.current - 1.day
    render DateCircleComponent.new(
      date: yesterday,
      day_of_week: yesterday.strftime('%a'),
      month_day: yesterday.strftime('%b %-d'),
      completed: true,
      selected: false,
      has_reading: true
    )
  end

  def selected_and_completed
    today = Date.current
    render DateCircleComponent.new(
      date: today,
      day_of_week: today.strftime('%a'),
      month_day: today.strftime('%b %-d'),
      completed: true,
      selected: true,
      has_reading: true
    )
  end

  def no_reading_available
    future_date = Date.current + 10.days
    render DateCircleComponent.new(
      date: future_date,
      day_of_week: future_date.strftime('%a'),
      month_day: future_date.strftime('%b %-d'),
      completed: false,
      selected: false,
      has_reading: false
    )
  end

  def no_reading_selected
    future_date = Date.current + 5.days
    render DateCircleComponent.new(
      date: future_date,
      day_of_week: future_date.strftime('%a'),
      month_day: future_date.strftime('%b %-d'),
      completed: false,
      selected: true,
      has_reading: false
    )
  end

  def cross_month_transition
    # Show a date from end of previous month
    cross_month_date = Date.new(2025, 9, 1) - 2.days # Aug 30
    render DateCircleComponent.new(
      date: cross_month_date,
      day_of_week: cross_month_date.strftime('%a'),
      month_day: cross_month_date.strftime('%b %-d'),
      completed: true,
      selected: false,
      has_reading: true
    )
  end

  def weekend_day
    # Find next Saturday
    saturday = Date.current.beginning_of_week(:monday) + 5.days
    render DateCircleComponent.new(
      date: saturday,
      day_of_week: saturday.strftime('%a'),
      month_day: saturday.strftime('%b %-d'),
      completed: false,
      selected: false,
      has_reading: true
    )
  end

  def monday_start_of_week
    monday = Date.current.beginning_of_week(:monday)
    render DateCircleComponent.new(
      date: monday,
      day_of_week: monday.strftime('%a'),
      month_day: monday.strftime('%b %-d'),
      completed: true,
      selected: false,
      has_reading: true
    )
  end

  def all_variations_grid
    today = Date.current
    variations = [
      { name: "Default (unselected, not completed)", completed: false, selected: false, has_reading: true },
      { name: "Selected, not completed", completed: false, selected: true, has_reading: true },
      { name: "Completed, not selected", completed: true, selected: false, has_reading: true },
      { name: "Selected and completed", completed: true, selected: true, has_reading: true },
      { name: "No reading available", completed: false, selected: false, has_reading: false },
      { name: "No reading, selected", completed: false, selected: true, has_reading: false }
    ]

    render_with_template template: "date_circle_component_preview/all_variations_grid", locals: {
      variations: variations,
      base_date: today
    }
  end
end