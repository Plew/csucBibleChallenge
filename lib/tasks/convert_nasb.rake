namespace :convert_nasb do
  desc "Convert bolls.life NASB JSON (db/texts/nasb_bolls.json) to OT-only CSV format for Import"
  task json_to_csv: :environment do
    require "json"
    require "csv"

    json_path = Rails.root.join("db", "texts", "nasb_bolls.json")
    csv_path = Rails.root.join("db", "texts", "nasb_ot.csv")

    unless File.exist?(json_path)
      puts "Error: source file not found at #{json_path}"
      puts "Download it with: curl -o #{json_path} https://bolls.life/static/translations/NASB.json"
      exit 1
    end

    ot_book_names = [
      "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
      "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
      "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Songs",
      "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
      "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]

    # The bolls.life dump flattens all NASB double quotes to straight single
    # quotes and wraps supplied words in [brackets]. The existing NASB NT rows
    # (lubbock_texts.csv) use double quotes for speech with singles only for
    # nested speech, no brackets, and a capitalized first letter per verse.
    # The transforms below restore that style; validated against the 7,958
    # NT verse pairs already in the database (~97% byte-identical).

    clean = lambda do |t|
      t = t.tr(" ", " ")
      t = t.delete("[]")
      t = t.gsub("--", "—")
      t = t.gsub(/ +'(?=[ .,;:!?)]|$)/, "'")
      t = t.gsub(/\s+/, " ").strip
      first_alpha = t.index(/[A-Za-z]/)
      t[first_alpha] = t[first_alpha].upcase if first_alpha
      t
    end

    openers = [ " ", "(", "—", '"' ]
    closers = [ " ", ".", ",", ";", ":", "!", "?", ")", "—", "'", '"' ]
    quote_kind = lambda do |t, i|
      prev = i > 0 ? t[i - 1] : nil
      nxt = i + 1 < t.length ? t[i + 1] : nil
      return :apostrophe if prev&.match?(/[A-Za-z]/) && nxt&.match?(/[A-Za-z]/)
      return :open if (prev.nil? || openers.include?(prev)) && !nxt.nil? && nxt != " "
      return :close if !prev.nil? && prev != " " && (nxt.nil? || closers.include?(nxt))
      :other
    end

    # Restore double quotes for outermost speech, tracking nesting depth across
    # the verses of a chapter (speech often spans verses; a leading quote mark
    # on a verse inside ongoing speech is a re-opening of the current level,
    # not a new nesting level).
    restore_chapter = lambda do |texts|
      depth = 0
      texts.map do |t|
        t = clean.call(t)
        chars = t.chars
        seen_content = false
        t.each_char.with_index do |ch, i|
          unless ch == "'"
            seen_content = true if ch != " "
            next
          end
          case quote_kind.call(t, i)
          when :open
            if seen_content || depth == 0
              depth += 1
            end
            chars[i] = depth == 1 ? '"' : "'"
          when :close
            if depth > 0
              chars[i] = depth == 1 ? '"' : "'"
              depth -= 1
            end
          end
          seen_content = true
        end
        chars.join
      end
    end

    puts "Reading #{json_path}..."
    data = JSON.parse(File.read(json_path))
    ot = data.select { |v| v["book"] <= 39 }
    puts "OT verses in source: #{ot.size}"

    chapters = ot.group_by { |v| [ v["book"], v["chapter"] ] }.sort_by(&:first)

    text_id = 0
    CSV.open(csv_path, "w", col_sep: ";", encoding: "UTF-8") do |csv|
      csv << [ "TextID", "Version", "NT_Book", "NT_Chapter", "NT_Verse", "VerseBreak", "VerseText" ]
      chapters.each do |(book, chapter), rows|
        rows = rows.sort_by { |v| v["verse"] }
        restored = restore_chapter.call(rows.map { |v| v["text"] })
        rows.zip(restored).each do |row, verse_text|
          text_id += 1
          # Encode double quotes as entities: Import strips literal double
          # quotes from the raw CSV field but decodes &quot; back afterwards.
          csv << [ text_id, "NASB", ot_book_names[book - 1], chapter, row["verse"], "No", verse_text.gsub('"', "&quot;") ]
        end
      end
    end

    puts "Wrote #{text_id} OT verses to #{csv_path}"
  end
end
