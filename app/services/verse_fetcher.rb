class VerseFetcher
  def self.fetch(version:, book_number:, chapter_number:)
    if version == "RCV"
      verses = RecoveryVersionClient.new.fetch_chapter(book_number:, chapter_number:)
      # Fall back to ESV if API fails (returns nil)
      return verses if verses.present?
      version = "ESV"
    end

    Verse.where(version:, book_number:, chapter_number:).order(:verse_number)
  end
end
