class CreatePokes < ActiveRecord::Migration[8.1]
  def change
    create_table :pokes do |t|
      t.integer :poker_id, null: false
      t.integer :pokee_id, null: false
      t.integer :challenge_id, null: false
      t.date :poked_on, null: false

      t.timestamps
    end

    add_index :pokes, [ :poker_id, :pokee_id, :challenge_id, :poked_on ], unique: true, name: "index_pokes_uniqueness"
    add_index :pokes, :pokee_id
    add_index :pokes, :challenge_id
  end
end
