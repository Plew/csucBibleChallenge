class RemoveVerseIdFromVerseMessages < ActiveRecord::Migration[8.0]
  def change
    # Remove the foreign key first
    remove_foreign_key :verse_messages, :verses

    # Remove the index
    remove_index :verse_messages, :verse_id

    # Remove the column
    remove_column :verse_messages, :verse_id, :integer
  end
end
