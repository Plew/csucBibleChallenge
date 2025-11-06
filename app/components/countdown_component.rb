class CountdownComponent < ViewComponent::Base
  def initialize(challenge:)
    @challenge = challenge
  end

  def target_datetime
    # Get 6am on the challenge start date in the challenge's timezone
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    start_date_6am.iso8601
  end

  def days_until_start
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    current_time = Time.current.in_time_zone(@challenge.timezone)

    time_diff = start_date_6am - current_time
    (time_diff / 1.day).ceil
  end

  def hours_until_start
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    current_time = Time.current.in_time_zone(@challenge.timezone)

    time_diff = start_date_6am - current_time
    ((time_diff % 1.day) / 1.hour).floor
  end

  def minutes_until_start
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    current_time = Time.current.in_time_zone(@challenge.timezone)

    time_diff = start_date_6am - current_time
    ((time_diff % 1.hour) / 1.minute).floor
  end

  def seconds_until_start
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    current_time = Time.current.in_time_zone(@challenge.timezone)

    time_diff = start_date_6am - current_time
    (time_diff % 1.minute).floor
  end

  def show_countdown?
    challenge_timezone = ActiveSupport::TimeZone.new(@challenge.timezone)
    start_date_6am = challenge_timezone.local(@challenge.start_date.year, @challenge.start_date.month, @challenge.start_date.day, 6, 0, 0)
    current_time = Time.current.in_time_zone(@challenge.timezone)

    current_time < start_date_6am
  end
end
