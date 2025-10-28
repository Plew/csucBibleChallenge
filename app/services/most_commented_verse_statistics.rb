# frozen_string_literal: true

class MostCommentedVerseStatistics
  attr_reader :challenge

  def initialize(challenge)
    @challenge = challenge
  end

  def most_commented_verse_today
    most_commented_verse_for_date(current_date_in_tz)
  end

  def most_commented_verse_for_date(date)
    date_start = date.in_time_zone(challenge.timezone).beginning_of_day
    date_end = date.in_time_zone(challenge.timezone).end_of_day

    # Find the verse with the most comments for this day
    most_commented = VerseMessage
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .where("verse_messages.created_at >= ? AND verse_messages.created_at <= ?", date_start, date_end)
      .group("verse_messages.reading_id", "verse_messages.verse_number")
      .select("verse_messages.reading_id, verse_messages.verse_number, COUNT(*) as comment_count")
      .order("comment_count DESC")
      .first

    return nil unless most_commented

    reading = Reading.find(most_commented.reading_id)
    verse = Verse.find_by(
      version: "KJV",
      book_number: reading.book_number,
      chapter_number: reading.chapter_number,
      verse_number: most_commented.verse_number
    )

    {
      reading: reading,
      verse: verse,
      verse_number: most_commented.verse_number,
      comment_count: most_commented.comment_count,
      book_name: book_number_to_name(reading.book_number),
      chapter_number: reading.chapter_number
    }
  end

  def total_comments_today
    date_start = current_date_in_tz.in_time_zone(challenge.timezone).beginning_of_day
    date_end = current_date_in_tz.in_time_zone(challenge.timezone).end_of_day

    VerseMessage
      .joins(:reading)
      .where(readings: { challenge_id: challenge.id })
      .where("verse_messages.created_at >= ? AND verse_messages.created_at <= ?", date_start, date_end)
      .count
  end

  private

  def current_date_in_tz
    Time.current.in_time_zone(challenge.timezone).to_date
  end

  def book_number_to_name(book_number)
    book_keys = %w[
      genesis exodus leviticus numbers deuteronomy joshua judges ruth first_samuel second_samuel first_kings second_kings first_chronicles second_chronicles ezra nehemiah esther job psalms proverbs ecclesiastes song_of_songs isaiah jeremiah lamentations ezekiel daniel hosea joel amos obadiah jonah micah nahum habakkuk zephaniah haggai zechariah malachi matthew mark luke john acts romans first_corinthians second_corinthians galatians ephesians philippians colossians first_thessalonians second_thessalonians first_timothy second_timothy titus philemon hebrews james first_peter second_peter first_john second_john third_john jude revelation
    ]
    key = book_keys[book_number.to_i - 1]
    return nil unless key
    I18n.t("bible_books.#{key}")
  end
end
