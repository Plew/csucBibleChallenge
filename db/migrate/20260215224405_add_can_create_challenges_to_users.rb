class AddCanCreateChallengesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_create_challenges, :boolean, default: false, null: false
  end
end
