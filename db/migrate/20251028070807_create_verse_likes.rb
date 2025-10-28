class CreateVerseLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :verse_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.integer :verse_number, null: false

      t.timestamps
    end

    add_index :verse_likes, [ :user_id, :reading_id, :verse_number ], unique: true, name: 'index_verse_likes_on_user_reading_verse'
  end
end
