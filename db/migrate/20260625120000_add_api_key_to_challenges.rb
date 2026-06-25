class AddApiKeyToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :api_key, :string
    add_index :challenges, :api_key, unique: true
  end
end
