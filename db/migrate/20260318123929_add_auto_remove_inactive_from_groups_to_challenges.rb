class AddAutoRemoveInactiveFromGroupsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :auto_remove_inactive_from_groups, :boolean, default: false, null: false
  end
end
