class UserChallengeEnrollment < ApplicationRecord
  ROLES = [ "member", "organizer" ].freeze

  belongs_to :user
  belongs_to :challenge

  validates :user_id, uniqueness: { scope: :challenge_id, message: "already enrolled in this challenge" }
  validates :role, inclusion: { in: ROLES }

  after_create :send_initial_daily_reading_email

  def organizer?
    role == "organizer"
  end

  private

  def send_initial_daily_reading_email
    return unless user.daily_email?

    today = Time.current.in_time_zone(challenge.timezone).to_date
    return unless challenge.start_date <= today && challenge.end_date >= today

    readings = challenge.readings.where(scheduled_date: today).order(:book_number, :chapter_number).to_a
    return if readings.empty?

    first_reading = readings.first
    return if EmailLoginToken.exists?(user: user, reading: first_reading)

    login_token = EmailLoginToken.create!(
      user: user,
      challenge: challenge,
      reading: first_reading,
      sent_at: Time.current
    )

    UserMailer.daily_reading(user, readings, login_token).deliver_later
  end
end
