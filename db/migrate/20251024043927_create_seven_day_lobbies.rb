class CreateSevenDayLobbies < ActiveRecord::Migration[8.0]
  def change
    create_table :seven_day_lobbies do |t|
      t.integer :challenge_id, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :seven_day_lobbies, [:challenge_id, :user_id], unique: true
    add_index :seven_day_lobbies, :challenge_id
    add_index :seven_day_lobbies, :user_id
  end
end
