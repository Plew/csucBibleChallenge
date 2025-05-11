require 'csv'

class ImportKjv
  FILE_PATH = Rails.root.join('db', 'texts', 'KJV.csv')
  VERSION_NAME = 'KJV'.freeze

  def self.call
    new.call
  end

  def call
    processed_books = {}
    current_book_id = 0

    line_iterator = 0
    CSV.foreach(FILE_PATH, headers: false, liberal_parsing: true) do |row|
      line_iterator += 1

      if line_iterator == 1
        next
      end

      book_name = row[0]
      chapter_number = row[1].to_i
      verse_number = row[2].to_i
      verse_text = row[3]&.strip

      unless processed_books.key?(book_name)
        current_book_id += 1
        processed_books[book_name] = current_book_id
      end

      book_id_for_verse = processed_books[book_name]

      Verse.find_or_create_by!(
        version: VERSION_NAME,
        book_number: book_id_for_verse,
        chapter_number: chapter_number,
        verse_number: verse_number
      ) do |verse|
        verse.verse_text = verse_text
      end
    end

    Rails.logger.info "Successfully imported/verified #{Verse.where(version: VERSION_NAME).count} KJV verses."
    Rails.logger.info "A total of #{current_book_id} unique KJV books were processed."
  rescue StandardError => e
    Rails.logger.error "KJV Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end 