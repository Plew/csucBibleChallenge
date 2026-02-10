class AddHideCopyrightToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :hide_copyright, :boolean, default: false, null: false
  end
end
