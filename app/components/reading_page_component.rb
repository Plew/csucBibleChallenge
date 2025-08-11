# frozen_string_literal: true

class ReadingPageComponent < ViewComponent::Base
  def initialize(
    days:,
    selected_date: nil,
    reading_title: nil,
    verses: [],
    is_completed: false,
    mobile: true,
    show_no_reading: false,
    challenge_name: "Reading Challenge"
  )
    @days = days
    @selected_date = selected_date
    @reading_title = reading_title
    @verses = verses
    @is_completed = is_completed
    @mobile = mobile
    @show_no_reading = show_no_reading
    @challenge_name = challenge_name
  end

  private

  def has_reading?
    !@show_no_reading && @reading_title.present? && @verses.any?
  end
  
  def selected_date_formatted
    return "today" if @selected_date == Date.current
    @selected_date&.strftime('%B %-d, %Y')
  end
end