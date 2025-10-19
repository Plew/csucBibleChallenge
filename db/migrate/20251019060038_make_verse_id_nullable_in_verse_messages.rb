class MakeVerseIdNullableInVerseMessages < ActiveRecord::Migration[8.0]
  def change
    change_column_null :verse_messages, :verse_id, true
  end
end
