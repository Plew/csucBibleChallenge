namespace :convert_asv do
  desc "Convert scrollmapper ASV JSON (cross-checked against bolls.life ASV) to OT-only CSV format for Import"
  task json_to_csv: :environment do
    require "json"
    require "csv"

    sm_path = Rails.root.join("db", "texts", "asv_scrollmapper.json")
    bolls_path = Rails.root.join("db", "texts", "asv_bolls.json")
    csv_path = Rails.root.join("db", "texts", "asv_ot.csv")

    unless File.exist?(sm_path) && File.exist?(bolls_path)
      puts "Error: source files required:"
      puts "  #{sm_path} from https://github.com/scrollmapper/bible_databases (formats/json/ASV.json)"
      puts "  #{bolls_path} from https://bolls.life/static/translations/ASV.json"
      exit 1
    end

    ot_book_names = [
      "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
      "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
      "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Songs",
      "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
      "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]

    capitalize_first = lambda do |t|
      i = t.index(/[A-Za-z]/)
      t[i] = t[i].upcase if i
      t
    end

    # Scrollmapper is the base text (bolls ASV mangles the first word of many
    # verses and is missing Song of Solomon 1:1), cleaned to match the style of
    # the existing ASV NT rows: straight apostrophes, no "[Selah" bracket, no
    # Psalm 119 acrostic headings, missing-space join artifacts repaired.
    clean_sm = lambda do |t|
      t = t.tr("’", "'").gsub("æ", "ae").gsub("Æ", "Ae")
      t = t.gsub("[Selah", "Selah")
      t = t.gsub(/\s*[֐-׿]\s+[A-Z]+\.\s*\z/, "")
      t = t.gsub(/([a-z])([A-Z])/, '\1 \2')
      t = t.gsub(/\s+/, " ").strip
      capitalize_first.call(t)
    end

    clean_bolls = lambda do |t|
      t = t.gsub(%r{<S>\d+</S>}, "").gsub(/<[^>]+>/, "")
      t = t.tr(" ", " ")
      t = t.gsub(/\s+([.,;:!?])/, '\1')
      t = t.gsub(/\s+/, " ").strip
      capitalize_first.call(t)
    end

    fix_hyphens = lambda do |t|
      t.gsub(/([A-Za-z]) +- *([A-Za-z])/, '\1-\2').gsub(/([A-Za-z]) *- +([A-Za-z])/, '\1-\2')
    end

    puts "Reading sources..."
    sm_data = JSON.parse(File.read(sm_path))
    verses = {}
    sm_data["books"].each_with_index do |book, bi|
      book["chapters"].each do |chapter|
        chapter["verses"].each do |v|
          verses[[ bi + 1, chapter["chapter"], v["verse"] ]] = clean_sm.call(v["text"])
        end
      end
    end
    verses.select! { |(book, _, _), _| book <= 39 }

    bolls = {}
    JSON.parse(File.read(bolls_path)).each do |v|
      next unless v["book"] <= 39
      bolls[[ v["book"], v["chapter"], v["verse"] ]] = clean_bolls.call(v["text"])
    end

    # Scrollmapper has ~600 verses with words run together ("he madethe stars").
    # Where the two sources differ only in spacing (ignoring the first word,
    # which bolls corrupts), adopt bolls' spacing, then normalize the stray
    # spaces bolls puts around hyphens ("first- fruits").
    adopted = 0
    verses.each do |key, text|
      other = bolls[key]
      next if other.nil? || other == text
      head, _, tail = text.partition(" ")
      other_tail = other.partition(" ").last
      next unless tail != other_tail && tail.delete(" ") == other_tail.delete(" ")
      verses[key] = "#{head} #{fix_hyphens.call(other_tail)}"
      adopted += 1
    end
    puts "OT verses: #{verses.size} (spacing adopted from bolls for #{adopted})"

    CSV.open(csv_path, "w", col_sep: ";", encoding: "UTF-8") do |csv|
      csv << [ "TextID", "Version", "NT_Book", "NT_Chapter", "NT_Verse", "VerseBreak", "VerseText" ]
      verses.keys.sort.each_with_index do |key, i|
        book, chapter, verse = key
        # Encode double quotes as entities: Import strips literal double
        # quotes from the raw CSV field but decodes &quot; back afterwards.
        csv << [ i + 1, "ASV", ot_book_names[book - 1], chapter, verse, "No", verses[key].gsub('"', "&quot;") ]
      end
    end

    puts "Wrote #{verses.size} OT verses to #{csv_path}"
  end
end
