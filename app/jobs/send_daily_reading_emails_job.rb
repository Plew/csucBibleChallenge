class SendDailyReadingEmailsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active challenges
    Challenge.active.find_each do |challenge|
      # Get current time in the challenge's timezone
      current_time_in_tz = Time.current.in_time_zone(challenge.timezone)

      # Only send emails at 6am in this timezone (check if it's between 6:00 and 6:59)
      next unless current_time_in_tz.hour == 6

      # Get today's reading for this challenge
      today = current_time_in_tz.to_date
      reading = challenge.readings.find_by(scheduled_date: today)

      # Skip if there's no reading scheduled for today
      next unless reading

      # Find all users enrolled in this challenge who want daily emails
      challenge.users.wants_daily_email.find_each do |user|
        # Create a login token for this user/reading
        login_token = EmailLoginToken.create!(
          user: user,
          challenge: challenge,
          reading: reading,
          sent_at: Time.current
        )

        # Send the email
        UserMailer.daily_reading(user, reading, login_token).deliver_now
      end
    end
  end
end
