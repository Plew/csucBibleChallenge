class AddTimezoneToChallenges < ActiveRecord::Migration[8.0]
  def change
    add_column :challenges, :timezone, :string
  end
end
