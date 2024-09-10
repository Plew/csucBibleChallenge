class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :device_id
      t.string :name

      t.timestamps
    end
    add_index :users, :device_id
  end
end
