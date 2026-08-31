class VerseFetcher
  GERMAN_VERSIONS = %w[ELB2006 SCHL2000].freeze
  ENGLISH_VERSIONS = %w[ESV NASB ASV KJV NKJV].freeze

  def self.fetch(version:, book_number:, chapter_number:)
    fetch_with_version(version: version, book_number: book_number, chapter_number: chapter_number)[:verses]
  end

  def self.fetch_with_version(version:, book_number:, chapter_number:)
    requested_version = version.to_s.upcase.presence || "ESV"

    # If user selected Recovery Version (RCV)
    if requested_version == "RCV"
      verses = RecoveryVersionClient.new.fetch_chapter(book_number: book_number, chapter_number: chapter_number)
      if verses.present?
        return { verses: verses, version: "RCV" }
      end
      # If RCV is unavailable for this chapter/book, fall back to English versions
      requested_version = "ESV"
    end

    is_german = GERMAN_VERSIONS.include?(requested_version)

    fallback_order = if is_german
      [ requested_version ] + (GERMAN_VERSIONS - [ requested_version ])
    else
      [ requested_version ] + (ENGLISH_VERSIONS - [ requested_version ])
    end

    fallback_order.each do |ver|
      verses = Verse.where(version: ver, book_number: book_number, chapter_number: chapter_number).order(:verse_number).to_a
      if verses.present?
        return { verses: verses, version: ver }
      end
    end

    # Emergency fallback for English requests (e.g. partial test database)
    if !is_german
      verses = Verse.where(version: ENGLISH_VERSIONS, book_number: book_number, chapter_number: chapter_number).order(:verse_number).to_a
      if verses.present?
        first_ver = verses.first.version
        verses = verses.select { |v| v.version == first_ver }
        return { verses: verses, version: first_ver }
      end
    end

    # Absolute fallback to whatever single version exists in the database for this chapter
    single_version = Verse.where(book_number: book_number, chapter_number: chapter_number).distinct.pick(:version)
    if single_version
      verses = Verse.where(version: single_version, book_number: book_number, chapter_number: chapter_number).order(:verse_number).to_a
      return { verses: verses, version: single_version }
    end

    { verses: [], version: requested_version }
  end
end
