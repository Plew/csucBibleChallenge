class RenameAdminRoleToOrganizerInEnrollments < ActiveRecord::Migration[8.0]
  def up
    UserChallengeEnrollment.where(role: "admin").update_all(role: "organizer")
  end

  def down
    UserChallengeEnrollment.where(role: "organizer").update_all(role: "admin")
  end
end
