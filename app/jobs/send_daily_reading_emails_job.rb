class SendDailyReadingEmailsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active challenges
    Challenge.active.find_each do |challenge|
      # Get current time in the challenge's timezone
      current_time_in_tz = Time.current.in_time_zone(challenge.timezone)
      current_hour = current_time_in_tz.hour

      # Get today's readings for this challenge (in the challenge's timezone)
      today = current_time_in_tz.to_date
      readings = challenge.readings.where(scheduled_date: today).order(:book_number, :chapter_number).to_a

      # Skip if there are no readings scheduled for today
      next if readings.empty?

      first_reading = readings.first

      # Find all users enrolled in this challenge who want daily emails at this current hour
      challenge.users.wants_daily_email.where("COALESCE(daily_email_hour, 6) = ?", current_hour).find_each do |user|
        # Guard against duplicates: skip if a token already exists for this user+reading today
        next if EmailLoginToken.exists?(user: user, reading: first_reading)

        # Create a login token for this user/reading
        login_token = EmailLoginToken.create!(
          user: user,
          challenge: challenge,
          reading: first_reading,
          sent_at: Time.current
        )

        # Send the single combined email for all chapters today
        UserMailer.daily_reading(user, readings, login_token).deliver_now
      end
    end
  end
end
