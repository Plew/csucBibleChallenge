# Shared Bible book naming + reference formatting for the API serializers.
module BibleBooks
  NAMES = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua",
    "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
    "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job",
    "Psalms", "Proverbs", "Ecclesiastes", "Song of Songs", "Isaiah", "Jeremiah",
    "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah",
    "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah",
    "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
    "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians",
    "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy",
    "Titus", "Philemon", "Hebrews", "James", "1 Peter", "2 Peter", "1 John",
    "2 John", "3 John", "Jude", "Revelation"
  ].freeze

  def self.name_for(book_number)
    NAMES[book_number - 1] || "Book #{book_number}"
  end

  # "Romans 8" for a chapter, "Romans 8:1" when a verse is given.
  def self.reference(book_number, chapter_number, verse_number = nil)
    ref = "#{name_for(book_number)} #{chapter_number}"
    verse_number ? "#{ref}:#{verse_number}" : ref
  end
end
