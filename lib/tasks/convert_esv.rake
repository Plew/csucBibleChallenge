namespace :convert_esv do
  desc "Convert ESV plain text (db/texts/esv.txt) to OT-only CSV format for Import"
  task txt_to_csv: :environment do
    require "csv"

    txt_path = Rails.root.join("db", "texts", "esv.txt")
    csv_path = Rails.root.join("db", "texts", "esv_ot.csv")

    unless File.exist?(txt_path)
      puts "Error: source file not found at #{txt_path}"
      exit 1
    end

    ot_abbrevs = %w[Gen Exo Lev Num Deu Jos Jdg Rut 1Sa 2Sa 1Ki 2Ki 1Ch 2Ch Ezr Neh Est Job Psa Pro Ecc Sol Isa Jer Lam Eze Dan Hos Joe Amo Oba Jon Mic Nah Hab Zep Hag Zec Mal]
    nt_abbrevs = %w[Mat Mar Luk Joh Act Rom 1Co 2Co Gal Eph Phi Col 1Th 2Th 1Ti 2Ti Tit Phm Heb Jam 1Pe 2Pe 1Jo 2Jo 3Jo Jud Rev]
    all_abbrevs = ot_abbrevs + nt_abbrevs
    book_number = all_abbrevs.each_with_index.to_h { |a, i| [ a, i + 1 ] }
    ot_book_names = [
      "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
      "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
      "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Songs",
      "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
      "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
    ]

    puts "Reading #{txt_path}..."
    lines = File.read(txt_path, encoding: "bom|utf-8").split("\n").map(&:strip)
    lines.reject! { |l| l.empty? || l == "The Holy Bible" || l == "English Standard Version 2001 ESV" }
    text = lines.join(" ").gsub(/\s+/, " ")

    # The source hard-wraps lines mid-verse, so verse boundaries are found by
    # scanning for "Abbrev C:V " markers across the joined text. Markers can be
    # glued to the previous verse's last word (page-break artifacts), so no
    # leading word boundary is required.
    marker = /(#{all_abbrevs.join("|")}) (\d{1,3}):(\d{1,3}) /
    matches = text.to_enum(:scan, marker).map { Regexp.last_match }
    puts "Found #{matches.size} verse markers"

    verses = matches.each_with_index.map do |m, i|
      text_end = i + 1 < matches.size ? matches[i + 1].begin(0) : text.length
      {
        book: book_number[m[1]],
        chapter: m[2].to_i,
        verse: m[3].to_i,
        text: text[m.end(0)...text_end].strip
      }
    end

    # Known source defect: Malachi 3 has an empty "Mal 3:2" marker and every
    # following verse is numbered one too high (3:3..3:19 hold the text of
    # 3:2..3:18). Verify the defect is still present, then repair it.
    mal3 = verses.select { |v| v[:book] == 39 && v[:chapter] == 3 }
    unless mal3.size == 19 && mal3[1][:verse] == 2 && mal3[1][:text].empty?
      raise "Malachi 3 no longer matches the known off-by-one defect; re-check db/texts/esv.txt"
    end
    verses.reject! { |v| v[:book] == 39 && v[:chapter] == 3 && v[:verse] == 2 }
    verses.each { |v| v[:verse] -= 1 if v[:book] == 39 && v[:chapter] == 3 && v[:verse] >= 3 }

    # Psalm superscriptions are embedded in ALL CAPS at the start of verse 1
    # (e.g. "A PSALM OF DAVID. The LORD is my shepherd..."). The KJV rows in the
    # verses table omit superscriptions, so strip them here too: remove the
    # longest prefix that contains no lowercase letters and ends at a period.
    strip_title = lambda do |t|
      best = nil
      idx = t.index(".")
      while idx
        break if t[0..idx] =~ /[a-z]/
        best = idx
        idx = t.index(".", idx + 1)
      end
      return t unless best
      rest = t[(best + 1)..].to_s.strip
      rest.empty? ? t : rest
    end
    titles_stripped = 0
    verses.each do |v|
      next unless v[:book] == 19 && v[:verse] == 1
      stripped = strip_title.call(v[:text])
      titles_stripped += 1 if stripped != v[:text]
      v[:text] = stripped
    end
    puts "Stripped #{titles_stripped} psalm superscriptions"

    ot_verses = verses.select { |v| v[:book] <= 39 && !v[:text].empty? }

    # Sequence sanity check: verses must proceed canonically.
    prev = nil
    anomalies = []
    ot_verses.each do |v|
      cur = [ v[:book], v[:chapter], v[:verse] ]
      if prev
        pb, pc, pv = prev
        ok = (cur == [ pb, pc, pv + 1 ]) || (cur == [ pb, pc + 1, 1 ]) || (cur == [ pb + 1, 1, 1 ])
        anomalies << [ prev, cur ] unless ok
      end
      prev = cur
    end
    puts "Sequence anomalies: #{anomalies.size}"
    anomalies.each { |a| puts "  #{a.inspect}" }

    CSV.open(csv_path, "w", col_sep: ";", encoding: "UTF-8") do |csv|
      csv << [ "TextID", "Version", "NT_Book", "NT_Chapter", "NT_Verse", "VerseBreak", "VerseText" ]
      ot_verses.each_with_index do |v, i|
        # Encode double quotes as entities: Import strips literal double quotes
        # from the raw CSV field but decodes &quot; back afterwards.
        csv << [ i + 1, "ESV", ot_book_names[v[:book] - 1], v[:chapter], v[:verse], "No", v[:text].gsub('"', "&quot;") ]
      end
    end

    puts "Wrote #{ot_verses.size} OT verses to #{csv_path}"
  end
end
