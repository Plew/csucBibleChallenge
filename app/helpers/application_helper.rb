module ApplicationHelper
  def flash_class(level)
    case level
    when "notice" then "alert-info"
    when "success" then "alert-success"
    when "error" then "alert-error"
    when "alert" then "alert-warning"
    end
  end

  def current_challenge_for_navbar
    return unless logged_in?
    current_user.challenges.first
  end

  # Returns the English Bible book name for a given book number (1-based, 1 = Genesis, 66 = Revelation)
  def book_number_to_name(book_number)
    book_keys = %w[
      genesis exodus leviticus numbers deuteronomy joshua judges ruth first_samuel second_samuel first_kings second_kings first_chronicles second_chronicles ezra nehemiah esther job psalms proverbs ecclesiastes song_of_songs isaiah jeremiah lamentations ezekiel daniel hosea joel amos obadiah jonah micah nahum habakkuk zephaniah haggai zechariah malachi matthew mark luke john acts romans first_corinthians second_corinthians galatians ephesians philippians colossians first_thessalonians second_thessalonians first_timothy second_timothy titus philemon hebrews james first_peter second_peter first_john second_john third_john jude revelation
    ]
    key = book_keys[book_number.to_i - 1]
    return nil unless key
    I18n.t("bible_books.#{key}")
  end
end
