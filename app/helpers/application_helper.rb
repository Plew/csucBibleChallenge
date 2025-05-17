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

  # Generates an image tag for a user's avatar using Avatarro.
  #
  # @param user [Object] The user object. Must respond to `username`.
  # @param size_key [Symbol] The desired avatar size. Accepted values: `:tiny`, `:medium`, `:large`. Defaults to `:medium`.
  # @param html_options [Hash] Additional HTML options for the `image_tag` helper.
  # @return [String] An HTML image tag for the avatar, or an empty string if the user or username is blank.
  #
  # @example Basic usage with default medium size
  #   avatar_image_tag(current_user)
  #
  # @example Specifying a tiny size
  #   avatar_image_tag(@user, :tiny)
  #
  # @example Specifying a large size with additional CSS class
  #   avatar_image_tag(@user, :large, class: 'rounded-full ring ring-primary')
  def avatar_image_tag(user, size_key = :medium, html_options = {})
    return '' unless user&.username.present?

    sizes = {
      tiny: '24x24',
      medium: '36x36',
      large: '48x48'
    }

    # Default to medium size if an invalid key is provided
    dimension = sizes[size_key.to_sym] || sizes[:medium]

    # Merge provided html_options with the size option
    options = { size: dimension }.merge(html_options)

    image_tag(Avatarro.image(user.username), options)
  end
end
