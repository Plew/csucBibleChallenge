class BackfillVerseMessagesReadingAndVerseNumber < ActiveRecord::Migration[8.0]
  def up
    # Backfill reading_id and verse_number for existing verse_messages
    VerseMessage.find_each do |message|
      verse = Verse.find(message.verse_id)

      # Find the reading that matches this verse's book and chapter
      # We'll look in all challenges since we don't have a direct link
      reading = Reading.find_by(
        book_number: verse.book_number,
        chapter_number: verse.chapter_number
      )

      if reading
        message.update_columns(
          reading_id: reading.id,
          verse_number: verse.verse_number
        )
      else
        # Log a warning if we can't find a matching reading
        Rails.logger.warn "Could not find reading for verse_message #{message.id} (verse: #{verse.book_number}:#{verse.chapter_number}:#{verse.verse_number})"
      end
    end

    # Now make the columns non-nullable
    change_column_null :verse_messages, :reading_id, false
    change_column_null :verse_messages, :verse_number, false
  end

  def down
    # Make columns nullable again
    change_column_null :verse_messages, :reading_id, true
    change_column_null :verse_messages, :verse_number, true
  end
end
