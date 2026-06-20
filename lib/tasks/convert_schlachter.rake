namespace :convert_schlachter do
  desc "Convert Schlachter XML to CSV format for Import"
  task xml_to_csv: :environment do
    require "nokogiri"
    require "csv"
    xml_path = Rails.root.join("db", "fixtures", "de_schlachter.xml")
    csv_path = Rails.root.join("db", "texts", "schlachter_2000.csv")

    unless File.exist?(xml_path)
      puts "Error: XML file not found at #{xml_path}"
      exit 1
    end

    puts "Reading XML file..."
    xml_content = File.read(xml_path)

    puts "Parsing XML..."
    doc = Nokogiri::XML(xml_content)

    # Book name mapping from XML to Import format
    # Most names match, but we need to ensure consistency
    book_name_mapping = {
      "Song of Solomon" => "Song of Songs"  # Only difference
    }

    puts "Converting to CSV..."
    verse_count = 0

    CSV.open(csv_path, "w", col_sep: ";", encoding: "UTF-8") do |csv|
      # Write header
      csv << [ "TextID", "Version", "NT_Book", "NT_Chapter", "NT_Verse", "VerseBreak", "VerseText" ]

      text_id = 1

      # Iterate through books
      doc.xpath("//b").each do |book|
        book_name = book["n"]
        # Map to Import format if needed
        import_book_name = book_name_mapping[book_name] || book_name

        # Iterate through chapters
        book.xpath("./c").each do |chapter|
          chapter_num = chapter["n"].to_i

          # Iterate through verses
          chapter.xpath("./v").each do |verse|
            verse_num = verse["n"].to_i
            verse_text = verse.text.strip

            csv << [
              text_id,
              "SCHL2000",
              import_book_name,
              chapter_num,
              verse_num,
              "No",
              verse_text
            ]

            text_id += 1
            verse_count += 1

            # Progress indicator
            puts "Processed #{verse_count} verses..." if verse_count % 5000 == 0
          end
        end
      end
    end

    puts "\nConversion complete!"
    puts "Total verses converted: #{verse_count}"
    puts "Output file: #{csv_path}"

    # Verify the file was created
    if File.exist?(csv_path)
      file_size = File.size(csv_path)
      puts "File size: #{(file_size / 1024.0 / 1024.0).round(2)} MB"
    else
      puts "Error: Output file was not created!"
      exit 1
    end
  end
end
