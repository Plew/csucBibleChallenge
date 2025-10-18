class CreateVerseMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :verse_messages do |t|
      t.references :verse, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end

    add_index :verse_messages, :created_at
  end
end
