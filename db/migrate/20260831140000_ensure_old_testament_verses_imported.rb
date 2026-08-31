class EnsureOldTestamentVersesImported < ActiveRecord::Migration[8.1]
  def up
    # If ESV or KJV Old Testament verses (e.g. Genesis 1) are missing in the database, import them
    needs_esv_ot = !Verse.exists?(version: "ESV", book_number: 1, chapter_number: 1)
    needs_kjv_ot = !Verse.exists?(version: "KJV", book_number: 1, chapter_number: 1)

    if needs_esv_ot || needs_kjv_ot
      Import.call
    end
  end

  def down
  end
end
