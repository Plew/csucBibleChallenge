class AddDescriptionToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :description, :text
  end
end
