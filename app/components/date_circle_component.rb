# frozen_string_literal: true

class DateCircleComponent < ViewComponent::Base
  def initialize(date:, day_of_week:, month_day:, completed: false, selected: false, has_reading: true)
    @date = date
    @day_of_week = day_of_week
    @month_day = month_day
    @completed = completed
    @selected = selected
    @has_reading = has_reading
  end

  private

  attr_reader :date, :day_of_week, :month_day, :completed, :selected, :has_reading

  def link_url
    has_reading ? "/?date=#{date}" : '#'
  end

  def link_classes
    base_classes = "relative w-8 h-8 flex items-center justify-center"
    interactive_classes = has_reading ? "cursor-pointer hover:opacity-80" : "cursor-default"
    "#{base_classes} #{interactive_classes}"
  end

  def border_classes
    if selected
      "border-primary border-4"
    elsif has_reading
      "border-primary"
    else
      "border-base-200"
    end
  end

  def inner_circle_classes
    if completed
      "bg-success text-success-content"
    else
      "bg-base-200 text-base-content"
    end
  end

  def text_classes
    base_classes = "text-[10px] leading-tight whitespace-nowrap"
    style_classes = selected ? "font-bold text-primary" : "text-base-content/70"
    "#{base_classes} #{style_classes}"
  end
end