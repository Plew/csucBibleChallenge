module ApplicationHelper
  BADGE_ICONS = {
    "seedling" => "\u{1F331}",
    "book" => "\u{1F4D6}",
    "fire" => "\u{1F525}",
    "clock" => "\u23F0",
    "star" => "\u2B50",
    "people" => "\u{1F465}",
    "heart" => "\u2764\uFE0F",
    "sunrise" => "\u{1F305}",
    "moon" => "\u{1F319}",
    "sweat" => "\u{1F605}",
    "eyes" => "\u{1F440}",
    "wave" => "\u{1F44B}",
    "wolf" => "\u{1F43A}",
    "flex" => "\u{1F4AA}",
    "runner" => "\u{1F3C3}",
    "flag" => "\u{1F6A9}",
    "speech" => "\u{1F4AC}",
    "diamond" => "\u{1F48E}",
    "megaphone" => "\u{1F4E3}",
    "broken_heart" => "\u{1F494}",
    "detective" => "\u{1F575}\uFE0F"
  }.freeze

  def badge_icon(icon_key)
    BADGE_ICONS[icon_key.to_s] || "\u{1F3C6}"
  end

  def country_flag_emoji(code)
    return nil if code.blank?
    code.to_s.upcase.each_char.map { |c| (c.ord + 127_397).chr(Encoding::UTF_8) }.join
  end

  def group_name_with_flag(group)
    flag = country_flag_emoji(group.country_code)
    safe_join([ flag, group.name ].compact, " ")
  end

  def flash_class(level)
    case level.to_s
    when "notice", "info" then "alert-info"
    when "success" then "alert-success"
    when "error", "danger" then "alert-error"
    when "alert", "warning" then "alert-warning"
    when "badge" then "alert-success"
    else "alert-info"
    end
  end

  # Resolves the active challenge for the current user.
  # Memoized per request so the nav layout can call it multiple times cheaply.
  def active_challenge_for_nav
    return nil unless logged_in?
    @active_challenge_for_nav ||= current_active_challenge
  end

  # All challenges the current user is enrolled in.
  def enrolled_challenges_for_nav
    return [] unless logged_in?
    @enrolled_challenges_for_nav ||= current_user.challenges.order(end_date: :desc, name: :asc)
  end

  # Challenges this user directly manages (as creator or challenge organizer).
  # Returns an ActiveRecord::Relation ordered by name.
  def managed_challenges_for_nav
    return Challenge.none unless logged_in?
    @managed_challenges_for_nav ||= current_user.directly_managed_challenges
  end

  # Calculates today's reading completion status for a given challenge and user
  def reading_status_for_challenge(challenge, user = current_user)
    return { has_reading: false, read_today: false, read_count: 0, total_count: 0, reading_title: nil } unless user && challenge
    challenge.daily_reading_status(user)
  end

  # Renders the reusable reading status badge component
  def reading_status_badge(challenge = nil, user: current_user, variant: :compact, status: nil)
    render(ReadingStatusBadgeComponent.new(challenge: challenge, user: user, variant: variant, status: status))
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
  # @param size_key [Symbol] The desired avatar size. Accepted values: `:tiny`, `:medium`, `:large`, `:xlarge`, `:xxlarge`. Defaults to `:medium`.
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
    return "" unless user&.username.present?

    sizes = {
      tiny: "24x24",
      medium: "36x36",
      large: "48x48",
      xlarge: "64x64",
      xxlarge: "96x96"
    }

    # Default to medium size if an invalid key is provided
    dimension = sizes[size_key.to_sym] || sizes[:medium]
    default_class = "rounded-full object-cover"
    merged_class = [ default_class, html_options[:class] ].compact.join(" ")
    options = { size: dimension, class: merged_class }.merge(html_options.except(:class))

    if user.avatar.attached?
      begin
        variant =
          case size_key.to_sym
          when :tiny
            user.avatar.variant(:thumb).processed
          when :large
            user.avatar.variant(:large).processed
          when :xlarge
            user.avatar.variant(:xlarge).processed
          when :xxlarge
            user.avatar.variant(:xxlarge).processed
          else
            user.avatar.variant(:medium).processed
          end
        image_tag(variant, options)
      rescue ActiveStorage::FileNotFoundError, ActiveStorage::InvariableError
        # Fall back to generated avatar if file is missing or can't be transformed (e.g. SVG)
        image_tag(Avatarro.image(user.username), options)
      end
    else
      image_tag(Avatarro.image(user.username), options)
    end
  end

  # Renders Markdown text as HTML with YouTube embed support
  #
  # @param text [String] The markdown text to render
  # @return [String] HTML-safe rendered markdown
  #
  # @example
  #   markdown("**Bold text** and [a link](https://example.com)")
  #   markdown("Check out this video: [youtube:dQw4w9WgXcQ]")
  def markdown(text)
    return "" if text.blank?

    # First, replace YouTube shortcodes with placeholder tokens to protect them from markdown processing
    youtube_placeholders = {}
    text_with_placeholders = text.gsub(/\[youtube:([^\]]+)\]/) do |match|
      video_identifier = Regexp.last_match(1)
      video_id = extract_youtube_id(video_identifier)

      if video_id
        placeholder = "YOUTUBE_EMBED_#{SecureRandom.hex(8)}"
        youtube_placeholders[placeholder] = youtube_iframe(video_id)
        placeholder
      else
        match
      end
    end

    options = {
      filter_html: false,  # We sanitize afterward with sanitize_with_youtube
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" },
      no_styles: true
    }

    extensions = {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown_renderer = Redcarpet::Markdown.new(renderer, extensions)

    # Render markdown with placeholders
    rendered = markdown_renderer.render(text_with_placeholders)

    # Replace placeholders with actual YouTube iframes
    youtube_placeholders.each do |placeholder, iframe_html|
      rendered = rendered.gsub(placeholder, iframe_html)
    end

    # Sanitize allowing YouTube iframes
    sanitize_with_youtube(rendered).html_safe
  end

  # Processes YouTube shortcodes and converts them to iframe embeds
  #
  # @param text [String] Text containing [youtube:VIDEO_ID] or [youtube:URL] shortcodes
  # @return [String] Text with YouTube embeds converted to iframe HTML
  #
  # @example
  #   process_youtube_embeds("[youtube:dQw4w9WgXcQ]")
  #   process_youtube_embeds("[youtube:https://www.youtube.com/watch?v=dQw4w9WgXcQ]")
  def process_youtube_embeds(text)
    # Match [youtube:VIDEO_ID] or [youtube:URL]
    text.gsub(/\[youtube:([^\]]+)\]/) do |match|
      video_identifier = Regexp.last_match(1)
      video_id = extract_youtube_id(video_identifier)

      if video_id
        youtube_iframe(video_id)
      else
        match # Return original if we can't extract a valid ID
      end
    end
  end

  # Extracts YouTube video ID from various URL formats or returns the ID if already provided
  #
  # @param identifier [String] YouTube video ID or URL
  # @return [String, nil] The video ID or nil if invalid
  #
  # @example
  #   extract_youtube_id("dQw4w9WgXcQ") # => "dQw4w9WgXcQ"
  #   extract_youtube_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ") # => "dQw4w9WgXcQ"
  #   extract_youtube_id("https://youtu.be/dQw4w9WgXcQ") # => "dQw4w9WgXcQ"
  def extract_youtube_id(identifier)
    return nil if identifier.blank?

    # If it looks like a URL, parse it
    if identifier.include?("youtube.com") || identifier.include?("youtu.be")
      uri = URI.parse(identifier) rescue nil
      return nil unless uri

      if uri.host&.include?("youtube.com")
        # Extract from ?v= parameter
        params = CGI.parse(uri.query || "")
        params["v"]&.first
      elsif uri.host&.include?("youtu.be")
        # Extract from path
        uri.path[1..]
      end
    else
      # Assume it's already a video ID - validate it's alphanumeric with dashes/underscores
      identifier.match?(/^[\w-]{11}$/) ? identifier : nil
    end
  end

  # Generates a safe YouTube iframe embed
  #
  # @param video_id [String] The YouTube video ID
  # @return [String] HTML iframe embed code
  def youtube_iframe(video_id)
    <<~HTML
      <div class="relative w-full" style="padding-bottom: 56.25%;">
        <iframe
          class="absolute top-0 left-0 w-full h-full rounded-lg"
          src="https://www.youtube-nocookie.com/embed/#{ERB::Util.html_escape(video_id)}"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowfullscreen>
        </iframe>
      </div>
    HTML
  end

  # Sanitizes HTML while allowing YouTube iframes
  #
  # @param html [String] HTML to sanitize
  # @return [String] Sanitized HTML
  def sanitize_with_youtube(html)
    # Use Rails sanitize with custom scrubber for YouTube iframes
    scrubber = Loofah::Scrubber.new do |node|
      # Allow text nodes
      if node.type == Nokogiri::XML::Node::TEXT_NODE
        Loofah::Scrubber::CONTINUE
      elsif node.name == "iframe"
        # Only allow iframes from YouTube
        src = node["src"]
        if src && (src.start_with?("https://www.youtube-nocookie.com/embed/", "https://www.youtube.com/embed/"))
          # Keep the iframe and its safe attributes
          node.attributes.each do |name, attr|
            unless %w[src frameborder allow allowfullscreen class].include?(name)
              attr.remove
            end
          end
          Loofah::Scrubber::CONTINUE
        else
          node.remove
          Loofah::Scrubber::STOP
        end
      elsif node.name == "div"
        # Allow divs with class and style (for video wrapper)
        node.attributes.each do |name, attr|
          unless %w[class style].include?(name)
            attr.remove
          end
        end
        Loofah::Scrubber::CONTINUE
      elsif %w[p br strong em a ul ol li blockquote code pre h1 h2 h3 h4 h5 h6].include?(node.name)
        # Standard allowed tags
        if node.name == "a"
          # Only keep href, target, rel for links
          node.attributes.each do |name, attr|
            unless %w[href target rel].include?(name)
              attr.remove
            end
          end
        else
          # Remove all attributes from other tags
          node.attributes.each { |name, attr| attr.remove }
        end
        Loofah::Scrubber::CONTINUE
      else
        # Remove any other tags
        node.remove
        Loofah::Scrubber::STOP
      end
    end

    Loofah.fragment(html).scrub!(scrubber).to_s
  end

  # Returns timezone options for select boxes
  # Prioritizes US timezones at the top, followed by all others alphabetically.
  #
  # @return [Array<Array>] Array of [display_name, timezone_identifier] pairs
  #
  # @example
  #   timezone_options_for_select
  #   # => [["Abu Dhabi", "Abu Dhabi"], ["America/New_York", "America/New_York"], ..., ["Munich", "Berlin"]]
  def timezone_options_for_select
    us_zones = ActiveSupport::TimeZone.us_zones.map { |tz| [ tz.name, tz.name ] }
    other_zones = (ActiveSupport::TimeZone.all - ActiveSupport::TimeZone.us_zones).map { |tz| [ tz.name, tz.name ] }

    other_zones.sort_by!(&:first)

    us_zones + [ [ "-------------", "" ] ] + other_zones
  end

  # Converts URLs in text to clickable links
  #
  # @param text [String] The text containing URLs
  # @param html_options [Hash] HTML options to apply to the links (e.g., class, target)
  # @return [String] HTML-safe text with URLs converted to links
  #
  # @example
  #   linkify_urls("Check out https://example.com for more info")
  #   linkify_urls("Visit https://example.com", class: 'link link-primary')
  def linkify_urls(text, html_options = {})
    return "" if text.blank?

    # Regex to match URLs (http, https, and www)
    url_regex = %r{
      (https?://[^\s<]+)  # Match http:// or https:// followed by non-whitespace
      |
      (www\.[^\s<]+)      # Match www. followed by non-whitespace
    }x

    text.gsub(url_regex) do |url|
      # Add http:// to www. links
      href = url.start_with?("www.") ? "http://#{url}" : url

      # Build HTML attributes
      attrs = html_options.map { |k, v| "#{k}=\"#{ERB::Util.html_escape(v)}\"" }.join(" ")

      "<a href=\"#{ERB::Util.html_escape(href)}\" #{attrs}>#{ERB::Util.html_escape(url)}</a>"
    end.html_safe
  end
end
