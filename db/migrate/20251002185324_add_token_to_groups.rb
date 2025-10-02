class AddTokenToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :token, :string
    add_index :groups, :token, unique: true
  end
end
