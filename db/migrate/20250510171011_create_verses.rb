class CreateVerses < ActiveRecord::Migration[8.0]
  def change
    create_table :verses do |t|
      t.string :version
      t.integer :book_number
      t.integer :chapter_number
      t.integer :verse_number
      t.text :verse_text

      t.timestamps
    end
    add_index :verses, :version
    add_index :verses, :book_number
    add_index :verses, :chapter_number
    add_index :verses, :verse_number
  end
end
