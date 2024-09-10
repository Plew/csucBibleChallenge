class CreateDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :devices do |t|
      t.string :device_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :devices, :device_id
  end
end
