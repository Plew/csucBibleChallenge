require 'csv'
require 'cgi'

class Import
  FILE_PATH = Rails.root.join('db', 'texts', 'lubbock_texts.csv')

  # Map book names to book numbers based on ApplicationHelper.book_number_to_name
  # Includes both "First/Second" and "1/2" naming formats from CSV
  BOOK_NAME_TO_NUMBER = {
    'Genesis' => 1, 'Exodus' => 2, 'Leviticus' => 3, 'Numbers' => 4, 'Deuteronomy' => 5,
    'Joshua' => 6, 'Judges' => 7, 'Ruth' => 8, 'First Samuel' => 9, 'Second Samuel' => 10,
    'First Kings' => 11, 'Second Kings' => 12, 'First Chronicles' => 13, 'Second Chronicles' => 14,
    'Ezra' => 15, 'Nehemiah' => 16, 'Esther' => 17, 'Job' => 18, 'Psalms' => 19,
    'Proverbs' => 20, 'Ecclesiastes' => 21, 'Song of Songs' => 22, 'Isaiah' => 23, 'Jeremiah' => 24,
    'Lamentations' => 25, 'Ezekiel' => 26, 'Daniel' => 27, 'Hosea' => 28, 'Joel' => 29,
    'Amos' => 30, 'Obadiah' => 31, 'Jonah' => 32, 'Micah' => 33, 'Nahum' => 34,
    'Habakkuk' => 35, 'Zephaniah' => 36, 'Haggai' => 37, 'Zechariah' => 38, 'Malachi' => 39,
    'Matthew' => 40, 'Mark' => 41, 'Luke' => 42, 'John' => 43, 'Acts' => 44,
    'Romans' => 45, 'Galatians' => 48, 'Ephesians' => 49, 'Philippians' => 50, 'Colossians' => 51,
    'Titus' => 56, 'Philemon' => 57, 'Hebrews' => 58, 'James' => 59, 'Jude' => 65, 'Revelation' => 66,
    
    # Numbered books - "First/Second" format
    'First Corinthians' => 46, 'Second Corinthians' => 47,
    'First Thessalonians' => 52, 'Second Thessalonians' => 53,
    'First Timothy' => 54, 'Second Timothy' => 55,
    'First Peter' => 60, 'Second Peter' => 61,
    'First John' => 62, 'Second John' => 63, 'Third John' => 64,
    
    # Numbered books - "1/2/3" format (from CSV)
    '1 Corinthians' => 46, '2 Corinthians' => 47,
    '1 Thessalonians' => 52, '2 Thessalonians' => 53,
    '1 Timothy' => 54, '2 Timothy' => 55,
    '1 Peter' => 60, '2 Peter' => 61,
    '1 John' => 62, '2 John' => 63, '3 John' => 64
  }.freeze

  def self.call
    new.call
  end

  def call
    verses = []
    line_count = 0
    skipped_count = 0

    Rails.logger.info "Starting import from #{FILE_PATH}"

    CSV.foreach(FILE_PATH, headers: true, col_sep: ';', liberal_parsing: true, encoding: 'UTF-8:UTF-8', invalid: :replace, undef: :replace, replace: '') do |row|
      line_count += 1
      
      # Parse CSV columns: TextID, Version, NT_Book, NT_Chapter, NT_Verse, VerseBreak, VerseText
      text_id = row[0]&.strip&.tr('"', '')
      version = row[1]&.strip&.tr('"', '')
      book_name = row[2]&.strip&.tr('"', '')
      chapter_number = row[3]&.strip&.tr('"', '')&.to_i
      verse_number = row[4]&.strip&.tr('"', '')&.to_i
      verse_break = row[5]&.strip&.tr('"', '')
      verse_text = row[6]&.strip&.tr('"', '')

      # Skip header row or invalid rows
      next if text_id == 'TextID' || version.blank? || book_name.blank? || verse_text.blank?

      # Get book number from mapping
      book_number = BOOK_NAME_TO_NUMBER[book_name]
      unless book_number
        Rails.logger.warn "Unknown book name: #{book_name} (line #{line_count})"
        skipped_count += 1
        next
      end

      # Decode HTML entities in verse text
      cleaned_verse_text = decode_html_entities(verse_text)

      verses << {
        version: version,
        book_number: book_number,
        chapter_number: chapter_number,
        verse_number: verse_number,
        verse_text: cleaned_verse_text,
        created_at: Time.current,
        updated_at: Time.current
      }

      # Process in batches to avoid memory issues
      if verses.size >= 1000
        upsert_verses(verses)
        verses.clear
      end
    end

    # Process remaining verses
    upsert_verses(verses) if verses.any?

    Rails.logger.info "Successfully processed #{line_count} lines."
    Rails.logger.info "Imported verses from #{BOOK_NAME_TO_NUMBER.keys & get_imported_books} books."
    Rails.logger.info "Skipped #{skipped_count} lines due to unknown book names." if skipped_count > 0
    Rails.logger.info "Import completed successfully."

  rescue StandardError => e
    Rails.logger.error "Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def decode_html_entities(text)
    return text if text.blank?
    
    # Decode specific HTML entities found in the CSV
    text = text.gsub('&ldquo;', '"')  # left double quotation mark
    text = text.gsub('&rdquo;', '"')  # right double quotation mark  
    text = text.gsub('&lsquo;', "'")  # left single quotation mark
    text = text.gsub('&rsquo;', "'")  # right single quotation mark
    text = text.gsub('&quot;', '"')   # quotation mark
    text = text.gsub('&amp;', '&')    # ampersand
    text = text.gsub('&lt;', '<')     # less than
    text = text.gsub('&gt;', '>')     # greater than
    
    text
  end

  def upsert_verses(verses)
    return if verses.empty?

    # Process each verse individually for idempotent behavior
    counter = 0
    verses.each do |verse_attrs|
      verse = Verse.find_or_initialize_by(
        version: verse_attrs[:version],
        book_number: verse_attrs[:book_number],
        chapter_number: verse_attrs[:chapter_number],
        verse_number: verse_attrs[:verse_number]
      )
      # print version booknumber chapter number verse number every 1000 verses
      if counter % 1000 == 0
        puts "version: #{verse_attrs[:version]}, book_number: #{verse_attrs[:book_number]}, chapter_number: #{verse_attrs[:chapter_number]}, verse_number: #{verse_attrs[:verse_number]}"
      end
      counter += 1
      
      verse.verse_text = verse_attrs[:verse_text]
      verse.updated_at = verse_attrs[:updated_at]
      verse.save! if verse.changed?
    end

    Rails.logger.info "Processed batch of #{verses.size} verses"
  end

  def get_imported_books
    # Get list of unique book names that were imported
    Verse.distinct.pluck(:book_number).map do |book_num|
      BOOK_NAME_TO_NUMBER.key(book_num)
    end.compact
  end
end