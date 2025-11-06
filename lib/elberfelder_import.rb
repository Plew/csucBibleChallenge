require "nokogiri"
require "csv"
require "cgi"

class ElberfelderImport
  BIBLE_PATH = Rails.root.join("db", "fixtures", "ELB2006-RoundtripHTML")
  OUTPUT_PATH = Rails.root.join("db", "texts", "elberfelder_2006.csv")

  # Map German book abbreviations to English book names that match the existing BOOK_NAME_TO_NUMBER mapping
  # Note: Keys will be normalized to NFC form to handle Unicode combining characters
  GERMAN_TO_ENGLISH_BOOKS_RAW = {
    # Old Testament
    "1.Mose" => "Genesis",
    "2.Mose" => "Exodus",
    "3.Mose" => "Leviticus",
    "4.Mose" => "Numbers",
    "5.Mose" => "Deuteronomy",
    "Jos" => "Joshua",
    "Ri" => "Judges",
    "Rut" => "Ruth",
    "1.Sam" => "First Samuel",
    "2.Sam" => "Second Samuel",
    "1.Kön" => "First Kings",
    "2.Kön" => "Second Kings",
    "1.Chr" => "First Chronicles",
    "2.Chr" => "Second Chronicles",
    "Esra" => "Ezra",
    "Neh" => "Nehemiah",
    "Est" => "Esther",
    "Hiob" => "Job",
    "Ps" => "Psalms",
    "Spr" => "Proverbs",
    "Pred" => "Ecclesiastes",
    "Hld" => "Song of Songs",
    "Jes" => "Isaiah",
    "Jer" => "Jeremiah",
    "Klgl" => "Lamentations",
    "Hes" => "Ezekiel",
    "Dan" => "Daniel",
    "Hos" => "Hosea",
    "Joel" => "Joel",
    "Am" => "Amos",
    "Obd" => "Obadiah",
    "Jona" => "Jonah",
    "Mi" => "Micah",
    "Nah" => "Nahum",
    "Hab" => "Habakkuk",
    "Zef" => "Zephaniah",
    "Hag" => "Haggai",
    "Sach" => "Zechariah",
    "Mal" => "Malachi",

    # New Testament
    "Mt" => "Matthew",
    "Mk" => "Mark",
    "Lk" => "Luke",
    "Joh" => "John",
    "Apg" => "Acts",
    "Röm" => "Romans",
    "1.Kor" => "First Corinthians",
    "2.Kor" => "Second Corinthians",
    "Gal" => "Galatians",
    "Eph" => "Ephesians",
    "Phil" => "Philippians",
    "Kol" => "Colossians",
    "1.Thess" => "First Thessalonians",
    "2.Thess" => "Second Thessalonians",
    "1.Tim" => "First Timothy",
    "2.Tim" => "Second Timothy",
    "Tit" => "Titus",
    "Phlm" => "Philemon",
    "Hebr" => "Hebrews",
    "Jak" => "James",
    "1.Petr" => "First Peter",
    "2.Petr" => "Second Peter",
    "1.Joh" => "First John",
    "2.Joh" => "Second John",
    "3.Joh" => "Third John",
    "Jud" => "Jude",
    "Offb" => "Revelation"
  }.freeze

  # Normalize all keys to handle Unicode combining characters
  GERMAN_TO_ENGLISH_BOOKS = GERMAN_TO_ENGLISH_BOOKS_RAW.transform_keys { |k| k.unicode_normalize(:nfc) }.freeze

  def self.call
    new.call
  end

  def call
    Rails.logger.info "Starting Elberfelder Bible import from #{BIBLE_PATH}"

    verses = []
    text_id = 1
    total_files = 0
    processed_files = 0

    # Process Old Testament files
    ot_path = BIBLE_PATH.join("ot")
    if ot_path.exist?
      Dir.glob(ot_path.join("*.html")).each do |file_path|
        total_files += 1
        verses.concat(process_html_file(file_path, text_id))
        processed_files += 1
        text_id = verses.last&.dig(:text_id)&.to_i&.+(1) || text_id

        Rails.logger.info "Processed #{processed_files}/#{total_files} files" if processed_files % 10 == 0
      end
    end

    # Process New Testament files
    nt_path = BIBLE_PATH.join("nt")
    if nt_path.exist?
      Dir.glob(nt_path.join("*.html")).each do |file_path|
        total_files += 1
        verses.concat(process_html_file(file_path, text_id))
        processed_files += 1
        text_id = verses.last&.dig(:text_id)&.to_i&.+(1) || text_id

        Rails.logger.info "Processed #{processed_files}/#{total_files} files" if processed_files % 10 == 0
      end
    end

    # Write to CSV
    write_csv(verses)

    Rails.logger.info "Successfully processed #{processed_files} HTML files"
    Rails.logger.info "Generated #{verses.size} verse entries"
    Rails.logger.info "Output written to #{OUTPUT_PATH}"

  rescue StandardError => e
    Rails.logger.error "Elberfelder Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def process_html_file(file_path, starting_text_id)
    verses = []
    filename = File.basename(file_path, ".html")

    # Normalize Unicode to handle combining characters (like ö in Kön)
    filename = filename.unicode_normalize(:nfc)

    # Extract book abbreviation and chapter number from filename (e.g., "Mt_1" -> "Mt", 1)
    if filename =~ /^(.+)_(\d+)$/
      book_abbrev = $1.unicode_normalize(:nfc)
      chapter_number = $2.to_i
    else
      Rails.logger.warn "Could not parse filename: #{filename}"
      return verses
    end

    # Map German book abbreviation to English book name
    english_book_name = GERMAN_TO_ENGLISH_BOOKS[book_abbrev]
    unless english_book_name
      Rails.logger.warn "Unknown German book abbreviation: #{book_abbrev}"
      return verses
    end

    # Parse HTML file
    begin
      content = File.read(file_path, encoding: "UTF-8")
      doc = Nokogiri::HTML(content)

      # Find all verse divs
      verse_divs = doc.css("div.v")

      verse_divs.each_with_index do |verse_div, index|
        verse_number_element = verse_div.css("span.vn").first
        next unless verse_number_element

        verse_number = verse_number_element.text.strip.to_i
        next if verse_number == 0

        # Extract verse text, removing footnotes and other markup
        verse_text = extract_verse_text(verse_div)
        next if verse_text.blank?

        verses << {
          text_id: starting_text_id + verses.size,
          version: "ELB2006",
          book: english_book_name,
          chapter: chapter_number,
          verse: verse_number,
          verse_break: "No",
          verse_text: verse_text
        }
      end

    rescue StandardError => e
      Rails.logger.error "Error processing file #{file_path}: #{e.message}"
    end

    verses
  end

  def extract_verse_text(verse_div)
    # Clone the div to avoid modifying the original
    text_div = verse_div.dup

    # Remove verse number span
    text_div.css("span.vn").remove

    # Remove footnote links and superscripts
    text_div.css("sup.fnm").remove
    text_div.css('a[href^="#fn"]').remove

    # Remove section headings (h3 tags)
    text_div.css("h3").remove

    # Remove line breaks that are just formatting
    text_div.css("span.br-p").remove

    # Get the text content and clean it up
    text = text_div.inner_text.strip

    # Clean up whitespace
    text = text.gsub(/\s+/, " ").strip

    # Decode HTML entities
    text = CGI.unescapeHTML(text)

    text
  end

  def write_csv(verses)
    # Ensure the directory exists
    FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))

    CSV.open(OUTPUT_PATH, "w", col_sep: ";", encoding: "UTF-8") do |csv|
      # Write header
      csv << [ "TextID", "Version", "NT_Book", "NT_Chapter", "NT_Verse", "VerseBreak", "VerseText" ]

      # Write verses
      verses.each do |verse|
        csv << [
          verse[:text_id],
          verse[:version],
          verse[:book],
          verse[:chapter],
          verse[:verse],
          verse[:verse_break],
          verse[:verse_text]
        ]
      end
    end
  end
end
