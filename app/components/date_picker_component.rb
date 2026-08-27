# frozen_string_literal: true

class DatePickerComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(
    # Calendar/Reading mode args:
    selected_date: nil,
    challenge: nil,
    user: nil,
    # Form/Field mode args:
    form: nil,
    attribute: :start_date,
    label: nil,
    target: nil,
    change_action: nil,
    presets: true,
    input_class: nil
  )
    @selected_date = selected_date
    @challenge = challenge
    @user = user
    @display_month = (selected_date || Date.current).beginning_of_month

    @form = form
    @attribute = attribute
    @label = label
    @target = target
    @change_action = change_action
    @presets = presets
    @input_class = input_class
  end

  def form_mode?
    @form.present?
  end

  # ================= Form Field Helpers =================

  def label_text
    @label || @form.object&.class&.human_attribute_name(@attribute) || @attribute.to_s.humanize
  end

  def show_presets?
    @presets
  end

  def today_date
    Date.current.to_s
  end

  def tomorrow_date
    Date.tomorrow.to_s
  end

  def next_monday_date
    Date.current.next_occurring(:monday).to_s
  end

  def data_attributes
    data = {}
    data["challenge-creator-target"] = @target if @target.present?
    data["date-picker-target"] = "input"

    actions = ["click->date-picker#open", "focus->date-picker#open"]
    actions << "change->#{@change_action}" if @change_action.present?
    actions << "input->#{@change_action}" if @change_action.present?
    data["action"] = actions.join(" ")
    data
  end

  def input_classes
    "input input-bordered w-full pr-10 cursor-pointer bg-base-100 font-medium text-neutral focus:outline-primary #{@input_class}".strip
  end

  # ================= Calendar Grid Helpers =================

  private

  attr_reader :selected_date, :challenge, :user, :display_month

  def month_title
    display_month.strftime("%B %Y")
  end

  def prev_month
    (display_month - 1.month).strftime("%Y-%m-%d")
  end

  def next_month
    (display_month + 1.month).strftime("%Y-%m-%d")
  end

  def calendar_weeks
    first_of_month = display_month.beginning_of_month
    last_of_month = display_month.end_of_month

    calendar_start = first_of_month.beginning_of_week(:monday)
    calendar_end = last_of_month.end_of_week(:monday)

    weeks = []
    current_date = calendar_start

    while current_date <= calendar_end
      week = []
      7.times do
        week << build_day_data(current_date)
        current_date += 1.day
      end
      weeks << week
    end

    weeks
  end

  def build_day_data(date)
    in_month = date.month == display_month.month
    day_readings = (in_month && challenge) ? challenge.readings.where(scheduled_date: date) : []
    has_reading = day_readings.any?
    completed = has_reading && user && day_readings.all? { |r| user.user_readings.exists?(reading_id: r.id) }
    partial_completed = has_reading && !completed && user && day_readings.any? { |r| user.user_readings.exists?(reading_id: r.id) }
    is_selected = date == selected_date

    {
      date: date,
      day: date.day,
      in_month: in_month,
      has_reading: has_reading,
      completed: completed,
      partial_completed: partial_completed,
      is_selected: is_selected
    }
  end

  def day_classes(day)
    base = "w-8 h-8 flex items-center justify-center text-xs rounded-sm transition-colors"

    return "#{base} text-base-300" unless day[:in_month]

    if day[:completed]
      "#{base} bg-success text-success-content cursor-pointer hover:opacity-80"
    elsif day[:partial_completed]
      "#{base} bg-warning text-warning-content cursor-pointer hover:opacity-80"
    elsif day[:has_reading]
      if day[:is_selected]
        "#{base} bg-primary text-primary-content cursor-pointer"
      else
        "#{base} bg-base-200 text-base-content cursor-pointer hover:bg-base-300"
      end
    else
      "#{base} text-base-content/30"
    end
  end

  def day_content(day)
    return "" unless day[:in_month]

    if day[:completed]
      ""
    else
      day[:day].to_s
    end
  end

  def day_link(day)
    return nil unless day[:in_month] && day[:has_reading]

    "/reading?date=#{day[:date]}"
  end

  def weekday_names
    %w[M T W T F S S]
  end
end
