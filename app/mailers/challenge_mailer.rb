class ChallengeMailer < ApplicationMailer
  def daily_summary(challenge)
    @challenge = challenge
    @participants = challenge.users.includes(:user_challenge_enrollments)

    mail(
      to: challenge.creator.email,
      subject: "Daily Summary: #{challenge.name}"
    )
  end
end
