class AddReadingAndVerseNumberToVerseMessages < ActiveRecord::Migration[8.0]
  def change
    # Add new columns (nullable for now to allow data migration)
    add_reference :verse_messages, :reading, null: true, foreign_key: true, index: true
    add_column :verse_messages, :verse_number, :integer, null: true

    # Add composite index for efficient querying by reading + verse_number
    add_index :verse_messages, [ :reading_id, :verse_number ]
  end
end
