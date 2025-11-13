# Service class to add Bible books (as readings) to an existing challenge
# Books are added sequentially, following the last scheduled reading in the challenge
#
# Usage:
#   AddBooksToChallenge.new(challenge).call(41, 66) # Adds Mark through Revelation
#   AddBooksToChallenge.new(challenge).call(41) # Adds only Mark
#
class AddBooksToChallenge
  # Bible book chapter counts (book_number => chapter_count)
  BIBLE_STRUCTURE = {
    1 => 50,   # Genesis
    2 => 40,   # Exodus
    3 => 27,   # Leviticus
    4 => 36,   # Numbers
    5 => 34,   # Deuteronomy
    6 => 24,   # Joshua
    7 => 21,   # Judges
    8 => 4,    # Ruth
    9 => 31,   # 1 Samuel
    10 => 24,  # 2 Samuel
    11 => 22,  # 1 Kings
    12 => 25,  # 2 Kings
    13 => 29,  # 1 Chronicles
    14 => 36,  # 2 Chronicles
    15 => 10,  # Ezra
    16 => 13,  # Nehemiah
    17 => 10,  # Esther
    18 => 42,  # Job
    19 => 150, # Psalms
    20 => 31,  # Proverbs
    21 => 12,  # Ecclesiastes
    22 => 8,   # Song of Songs
    23 => 66,  # Isaiah
    24 => 52,  # Jeremiah
    25 => 5,   # Lamentations
    26 => 48,  # Ezekiel
    27 => 12,  # Daniel
    28 => 14,  # Hosea
    29 => 4,   # Joel
    30 => 9,   # Amos
    31 => 1,   # Obadiah
    32 => 4,   # Jonah
    33 => 7,   # Micah
    34 => 3,   # Nahum
    35 => 3,   # Habakkuk
    36 => 3,   # Zephaniah
    37 => 2,   # Haggai
    38 => 14,  # Zechariah
    39 => 4,   # Malachi
    40 => 28,  # Matthew
    41 => 16,  # Mark
    42 => 24,  # Luke
    43 => 21,  # John
    44 => 28,  # Acts
    45 => 16,  # Romans
    46 => 16,  # 1 Corinthians
    47 => 13,  # 2 Corinthians
    48 => 6,   # Galatians
    49 => 6,   # Ephesians
    50 => 5,   # Philippians
    51 => 4,   # Colossians
    52 => 5,   # 1 Thessalonians
    53 => 3,   # 2 Thessalonians
    54 => 6,   # 1 Timothy
    55 => 4,   # 2 Timothy
    56 => 3,   # Titus
    57 => 1,   # Philemon
    58 => 13,  # Hebrews
    59 => 5,   # James
    60 => 5,   # 1 Peter
    61 => 3,   # 2 Peter
    62 => 5,   # 1 John
    63 => 1,   # 2 John
    64 => 1,   # 3 John
    65 => 1,   # Jude
    66 => 22   # Revelation
  }.freeze

  attr_reader :challenge, :errors

  def initialize(challenge)
    @challenge = challenge
    @errors = []
  end

  # Adds books from start_book to end_book (inclusive) to the challenge
  # If end_book is nil, adds only start_book
  #
  # @param start_book [Integer] The first book number to add (1-66)
  # @param end_book [Integer, nil] The last book number to add (1-66), defaults to start_book
  # @return [Boolean] true if successful, false otherwise
  def call(start_book, end_book = nil)
    end_book ||= start_book

    unless valid_book_range?(start_book, end_book)
      @errors << "Invalid book range: #{start_book} to #{end_book}. Books must be between 1-66."
      return false
    end

    last_reading = challenge.readings.order(:scheduled_date).last
    unless last_reading
      @errors << "Challenge has no existing readings. Cannot determine start date."
      return false
    end

    # Start scheduling the day after the last reading
    next_date = last_reading.scheduled_date + 1.day

    ActiveRecord::Base.transaction do
      (start_book..end_book).each do |book_number|
        chapter_count = BIBLE_STRUCTURE[book_number]

        (1..chapter_count).each do |chapter_number|
          challenge.readings.create!(
            book_number: book_number,
            chapter_number: chapter_number,
            scheduled_date: next_date
          )
          next_date += 1.day
        end
      end

      # Update challenge end_date to match the last scheduled reading
      new_end_date = challenge.readings.order(:scheduled_date).last.scheduled_date
      challenge.update!(end_date: new_end_date)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Failed to add readings: #{e.message}"
    false
  end

  private

  def valid_book_range?(start_book, end_book)
    start_book.between?(1, 66) && end_book.between?(1, 66) && start_book <= end_book
  end
end
