class EnsureOldTestamentVersesImported < ActiveRecord::Migration[8.1]
  def up
    files_to_import = []

    # Check which specific files are missing verses in the database
    files_to_import << Rails.root.join("db", "texts", "esv_ot.csv") unless Verse.exists?(version: "ESV", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "nasb_ot.csv") unless Verse.exists?(version: "NASB", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "asv_ot.csv") unless Verse.exists?(version: "ASV", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "KJV.csv") unless Verse.exists?(version: "KJV", book_number: 1, chapter_number: 1)

    if files_to_import.any?
      Import.call(files_to_import)
    end
  end

  def down
  end
end
