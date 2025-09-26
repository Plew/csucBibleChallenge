class AddHiddenToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :hidden, :boolean, default: false, null: false
  end
end
