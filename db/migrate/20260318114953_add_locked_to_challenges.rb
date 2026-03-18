class AddLockedToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :locked, :boolean, default: false, null: false
  end
end
