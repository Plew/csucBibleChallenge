class CreateReadingPresences < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_presences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.datetime :last_heartbeat_at, null: false

      t.timestamps
    end

    add_index :reading_presences, [ :user_id, :reading_id ], unique: true
    add_index :reading_presences, [ :reading_id, :last_heartbeat_at ]
  end
end
