require "base64"
require "net/http"
require "ostruct"

class RecoveryVersionClient
  API_BASE_URL = "https://api.lsm.org/recver/txo.php".freeze
  MAX_VERSES_PER_REQUEST = 50

  # Maps book_number (1-66) to LSM API abbreviation format
  BOOK_ABBREVIATIONS = {
    1 => "Gen.", 2 => "Exo.", 3 => "Lev.", 4 => "Num.", 5 => "Deut.",
    6 => "Josh.", 7 => "Judg.", 8 => "Ruth", 9 => "1 Sam.", 10 => "2 Sam.",
    11 => "1 Kings", 12 => "2 Kings", 13 => "1 Chron.", 14 => "2 Chron.",
    15 => "Ezra", 16 => "Neh.", 17 => "Esth.", 18 => "Job", 19 => "Psa.",
    20 => "Prov.", 21 => "Eccl.", 22 => "S.S.", 23 => "Isa.", 24 => "Jer.",
    25 => "Lam.", 26 => "Ezek.", 27 => "Dan.", 28 => "Hosea", 29 => "Joel",
    30 => "Amos", 31 => "Obad.", 32 => "Jonah", 33 => "Micah", 34 => "Nahum",
    35 => "Hab.", 36 => "Zeph.", 37 => "Hag.", 38 => "Zech.", 39 => "Mal.",
    40 => "Matt.", 41 => "Mark", 42 => "Luke", 43 => "John", 44 => "Acts",
    45 => "Rom.", 46 => "1 Cor.", 47 => "2 Cor.", 48 => "Gal.", 49 => "Eph.",
    50 => "Phil.", 51 => "Col.", 52 => "1 Thes.", 53 => "2 Thes.",
    54 => "1 Tim.", 55 => "2 Tim.", 56 => "Titus", 57 => "Philem.",
    58 => "Heb.", 59 => "James", 60 => "1 Pet.", 61 => "2 Pet.",
    62 => "1 John", 63 => "2 John", 64 => "3 John", 65 => "Jude", 66 => "Rev."
  }.freeze

  def fetch_chapter(book_number:, chapter_number:)
    cache_key = "rcv_verses:#{book_number}:#{chapter_number}"

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      fetch_from_api(book_number, chapter_number)
    end
  rescue StandardError => e
    Rails.logger.error("RecoveryVersionClient error: #{e.message}")
    nil # VerseFetcher will fall back to ESV
  end

  private

  def fetch_from_api(book_number, chapter_number)
    book_abbrev = BOOK_ABBREVIATIONS[book_number]
    return nil unless book_abbrev

    all_verses = []
    verse_start = 1

    # Fetch in batches of 50 verses until we get fewer than requested
    loop do
      verse_end = verse_start + MAX_VERSES_PER_REQUEST - 1
      reference = "#{book_abbrev} #{chapter_number}:#{verse_start}-#{verse_end}"

      response = make_api_request(reference)
      break unless response

      parsed_verses = parse_response(response)

      if parsed_verses.empty?
        break
      else
        all_verses.concat(parsed_verses)
        # If we got fewer verses than requested, we've reached the end
        break if parsed_verses.length < MAX_VERSES_PER_REQUEST
      end

      verse_start = verse_end + 1

      # Safety limit: no chapter has more than 200 verses
      break if verse_start > 200
    end

    return nil if all_verses.empty?
    all_verses.sort_by(&:verse_number)
  end

  def make_api_request(reference)
    config = load_config
    return nil unless config && config["appid"] && config["token"]

    uri = URI(API_BASE_URL)
    uri.query = URI.encode_www_form(
      String: reference,
      Out: "json"
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    credentials = Base64.strict_encode64("#{config['appid']}:#{config['token']}")
    request["Authorization"] = "Basic #{credentials}"

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      Rails.logger.warn("RecoveryVersionClient API returned #{response.code}: #{response.message}")
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.error("RecoveryVersionClient network error: #{e.message}")
    nil
  end

  def load_config
    @config ||= begin
      config_path = File.expand_path("~/.claude/skills/bible-rcv/config.json")
      if File.exist?(config_path)
        JSON.parse(File.read(config_path))
      else
        Rails.logger.warn("RecoveryVersionClient: config.json not found at #{config_path}")
        nil
      end
    end
  end

  def parse_response(response_body)
    return [] unless response_body

    begin
      data = JSON.parse(response_body)
      verses_array = data["verses"]
      return [] if verses_array.blank?

      # API returns array of {ref: "John 3:16", text: "...", urlpfx: "..."}
      # Filter out "No such verse" responses
      verses_array.filter_map do |verse|
        text = verse["text"]
        next if text.blank? || text.start_with?("No such verse")

        # Extract verse number from ref like "John 3:16" -> 16
        verse_number = extract_verse_number(verse["ref"])
        next unless verse_number

        OpenStruct.new(
          verse_number: verse_number,
          verse_text: text
        )
      end
    rescue JSON::ParserError => e
      Rails.logger.error("RecoveryVersionClient JSON parse error: #{e.message}")
      []
    end
  end

  def extract_verse_number(ref)
    # Extract verse number from references like "John 3:16" or "1 Cor. 13:4"
    match = ref&.match(/:(\d+)\z/)
    match ? match[1].to_i : nil
  end
end
