module ReadingDateValidation
  extend ActiveSupport::Concern

  private

  def resolve_completed_on(scheduled_date, challenge)
    earliest_worldwide = (Time.current.utc - 12.hours).to_date
    latest_worldwide   = (Time.current.utc + 14.hours).to_date

    if scheduled_date > latest_worldwide
      raise FutureReadingError.new(scheduled_date)
    elsif scheduled_date >= earliest_worldwide
      scheduled_date
    else
      Time.current.in_time_zone(challenge.timezone).to_date
    end
  end

  def within_worldwide_window?(scheduled_date)
    earliest_worldwide = (Time.current.utc - 12.hours).to_date
    latest_worldwide   = (Time.current.utc + 14.hours).to_date
    scheduled_date.between?(earliest_worldwide, latest_worldwide)
  end

  class FutureReadingError < StandardError
    attr_reader :scheduled_date
    def initialize(scheduled_date)
      @scheduled_date = scheduled_date
      super("Cannot mark readings for future dates. This reading is scheduled for #{scheduled_date}.")
    end
  end
end
