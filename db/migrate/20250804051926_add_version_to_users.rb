class AddVersionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :version, :string, default: 'ESV'
  end
end
