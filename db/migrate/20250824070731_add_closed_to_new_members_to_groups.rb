class AddClosedToNewMembersToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :closed_to_new_members, :boolean, default: false, null: false
  end
end
