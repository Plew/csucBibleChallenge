class CreateUserReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_readings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.date :completed_on

      t.timestamps
    end
    add_index :user_readings, [:user_id, :reading_id], unique: true
  end
end
