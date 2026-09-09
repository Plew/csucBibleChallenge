class UserChallengeEnrollment < ApplicationRecord
  ROLES = [ "member", "organizer" ].freeze

  belongs_to :user
  belongs_to :challenge

  validates :user_id, uniqueness: { scope: :challenge_id, message: "already enrolled in this challenge" }
  validates :role, inclusion: { in: ROLES }

  after_create :send_initial_daily_reading_email
  after_destroy :cleanup_challenge_groups

  def organizer?
    role == "organizer"
  end

  private

  def cleanup_challenge_groups
    return if challenge.blank? || challenge.destroyed? || challenge.marked_for_destruction?
    return if user.blank? || user.destroyed? || user.marked_for_destruction?

    # 1. Groups this user is enrolled in for this challenge
    UserGroupEnrollment.joins(:group)
                       .where(user_id: user_id, groups: { challenge_id: challenge_id })
                       .find_each do |uge|
      group = uge.group
      if group.creator_id == user_id
        group.transfer_ownership_to_first_joined!(excluding: user)
      end
      uge.destroy
      group.destroy if group.user_group_enrollments.reload.empty?
    end

    # 2. In case user was creator of a group in this challenge but not enrolled in it
    Group.where(challenge_id: challenge_id, creator_id: user_id).find_each do |group|
      group.transfer_ownership_to_first_joined!(excluding: user)
      group.destroy if group.user_group_enrollments.reload.empty?
    end
  end

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
