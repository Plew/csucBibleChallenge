class RemoveInactiveUsersFromGroupsJob < ApplicationJob
  queue_as :default

  INACTIVE_DAYS = 10

  def perform
    Challenge.where(auto_remove_inactive_from_groups: true).find_each do |challenge|
      remove_inactive_users_for(challenge)
    end
  end

  private

  def remove_inactive_users_for(challenge)
    cutoff_date = INACTIVE_DAYS.days.ago.to_date

    # Find users in this challenge who have a group
    challenge.groups.includes(:users).find_each do |group|
      group.users.each do |user|
        has_recent_activity = UserReading.joins(:reading)
          .where(user: user, readings: { challenge_id: challenge.id })
          .where("user_readings.completed_on >= ?", cutoff_date)
          .exists?

        unless has_recent_activity
          UserGroupEnrollment.where(user: user, group: group).delete_all
          Rails.logger.info "[RemoveInactiveUsersFromGroupsJob] Removed #{user.username} (ID: #{user.id}) from group '#{group.name}' in challenge '#{challenge.name}' due to #{INACTIVE_DAYS} days of inactivity"
        end
      end
    end
  end
end
