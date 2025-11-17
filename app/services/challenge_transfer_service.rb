# Service class to handle transferring users between challenges
# including duplicating groups and maintaining group memberships
class ChallengeTransferService
  attr_reader :from_challenge, :to_challenge, :transferred_count, :skipped_count,
              :groups_duplicated, :errors

  def initialize(from_challenge, to_challenge)
    @from_challenge = from_challenge
    @to_challenge = to_challenge
    @transferred_count = 0
    @skipped_count = 0
    @groups_duplicated = 0
    @errors = []
    @group_mapping = {}
  end

  def call
    return false unless valid?

    duplicate_groups
    transfer_users
    true
  end

  def success_message
    "Successfully transferred #{transferred_count} users and duplicated #{groups_duplicated} groups. " \
    "#{skipped_count} users were already enrolled in the target challenge."
  end

  def error_message
    "Transfer completed with errors. #{transferred_count} users transferred, #{skipped_count} skipped, " \
    "#{groups_duplicated} groups duplicated. Errors: #{errors.join('; ')}"
  end

  private

  def valid?
    if from_challenge.id == to_challenge.id
      @errors << "Cannot transfer to the same challenge"
      return false
    end
    true
  end

  def duplicate_groups
    from_challenge.groups.each do |old_group|
      existing_group = to_challenge.groups.find_by(name: old_group.name)

      if existing_group
        @group_mapping[old_group.id] = existing_group.id
      else
        new_group = Group.new(
          name: old_group.name,
          challenge_id: to_challenge.id,
          creator_id: old_group.creator_id
        )

        if new_group.save
          @group_mapping[old_group.id] = new_group.id
          @groups_duplicated += 1
        else
          @errors << "Failed to duplicate group '#{old_group.name}': #{new_group.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def transfer_users
    from_challenge.user_challenge_enrollments.each do |enrollment|
      user = enrollment.user

      existing_enrollment = UserChallengeEnrollment.find_by(
        user_id: user.id,
        challenge_id: to_challenge.id
      )

      if existing_enrollment
        enrollment.destroy
        @skipped_count += 1
      else
        if enrollment.update(challenge_id: to_challenge.id)
          @transferred_count += 1
          transfer_user_group_memberships(user)
        else
          @errors << "Failed to transfer #{user.username}: #{enrollment.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def transfer_user_group_memberships(user)
    old_group_ids = from_challenge.groups.pluck(:id)
    user.user_group_enrollments.where(group_id: old_group_ids).each do |group_enrollment|
      old_group_id = group_enrollment.group_id
      new_group_id = @group_mapping[old_group_id]

      next unless new_group_id

      unless UserGroupEnrollment.exists?(user_id: user.id, group_id: new_group_id)
        UserGroupEnrollment.create!(
          user_id: user.id,
          group_id: new_group_id
        )
      end

      group_enrollment.destroy
    end
  end
end
