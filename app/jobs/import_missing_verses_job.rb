class ImportMissingVersesJob < ApplicationJob
  queue_as :default

  def perform
    files_to_import = []

    files_to_import << Rails.root.join("db", "texts", "esv_ot.csv") unless Verse.exists?(version: "ESV", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "nasb_ot.csv") unless Verse.exists?(version: "NASB", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "asv_ot.csv") unless Verse.exists?(version: "ASV", book_number: 1, chapter_number: 1)
    files_to_import << Rails.root.join("db", "texts", "KJV.csv") unless Verse.exists?(version: "KJV", book_number: 1, chapter_number: 1)

    if files_to_import.any?
      Rails.logger.info("ImportMissingVersesJob: Importing #{files_to_import.map { |f| File.basename(f) }.join(', ')}...")
      Import.call(files_to_import)
      Rails.logger.info("ImportMissingVersesJob: Verse import completed.")
    end
  end
end
