require 'rails_helper'

RSpec.describe Import do
  describe '.call' do
    let(:csv_content) do
      <<~CSV
        "TextID";"Version";"NT_Book";"NT_Chapter";"NT_Verse";"VerseBreak";"VerseText"
        "1";"NASB";"Matthew";"1";"1";"No";"The record of the genealogy of Jesus the Messiah, the son of David, the son of Abraham:"
        "21";"NASB";"Matthew";"1";"21";"No";"&ldquo;She will bear a Son; and you shall call His name Jesus, for He will save His people from their sins.&rdquo;"
        "23";"NASB";"Matthew";"1";"23";"No";"&ldquo;BEHOLD, THE VIRGIN SHALL BE WITH CHILD AND SHALL BEAR A SON, AND THEY SHALL CALL HIS NAME IMMANUEL,&rdquo; which translated means, &ldquo;GOD WITH US.&rdquo;"
        "31";"NASB";"Matthew";"2";"6";"Yes";"&lsquo;AND YOU, BETHLEHEM, LAND OF JUDAH, ARE BY NO MEANS LEAST AMONG THE LEADERS OF JUDAH; FOR OUT OF YOU SHALL COME FORTH A RULER WHO WILL SHEPHERD MY PEOPLE ISRAEL.&rsquo;&rdquo;"
        "52";"NASB";"Matthew";"3";"4";"No";"Now John himself had a garment of camel&rsquo;s hair and a leather belt around his waist; and his food was locusts and wild honey."
        "100";"KJV";"Mark";"1";"1";"No";"The beginning of the gospel of Jesus Christ, the Son of God;"
        "200";"ESV";"Luke";"1";"1";"No";"Inasmuch as many have undertaken to compile a narrative of the things that have been accomplished among us,"
      CSV
    end

    let(:temp_file) { Tempfile.new(['test_verses', '.csv']) }

    before do
      temp_file.write(csv_content)
      temp_file.close
      allow(Import).to receive(:const_get).with(:FILE_PATH).and_return(temp_file.path)
    end

    after do
      temp_file.unlink
    end

    it 'imports verses from CSV file' do
      expect { Import.call }.to change { Verse.count }.by(7)
    end

    it 'creates verses with correct attributes' do
      Import.call

      verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
      expect(verse).to be_present
      expect(verse.verse_text).to eq('The record of the genealogy of Jesus the Messiah, the son of David, the son of Abraham:')
    end

    it 'correctly maps book names to book numbers' do
      Import.call

      matthew_verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
      mark_verse = Verse.find_by(version: 'KJV', book_number: 41, chapter_number: 1, verse_number: 1)
      luke_verse = Verse.find_by(version: 'ESV', book_number: 42, chapter_number: 1, verse_number: 1)

      expect(matthew_verse).to be_present
      expect(mark_verse).to be_present
      expect(luke_verse).to be_present
    end

    context 'HTML entity decoding' do
      before { Import.call }

      it 'decodes &ldquo; and &rdquo; (double quotes)' do
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 21)
        expect(verse.verse_text).to eq('"She will bear a Son; and you shall call His name Jesus, for He will save His people from their sins."')
      end

      it 'decodes multiple HTML entities in one verse' do
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 23)
        expected_text = '"BEHOLD, THE VIRGIN SHALL BE WITH CHILD AND SHALL BEAR A SON, AND THEY SHALL CALL HIS NAME IMMANUEL," which translated means, "GOD WITH US."'
        expect(verse.verse_text).to eq(expected_text)
      end

      it 'decodes &lsquo; and &rsquo; (single quotes)' do
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 2, verse_number: 6)
        expected_text = "'AND YOU, BETHLEHEM, LAND OF JUDAH, ARE BY NO MEANS LEAST AMONG THE LEADERS OF JUDAH; FOR OUT OF YOU SHALL COME FORTH A RULER WHO WILL SHEPHERD MY PEOPLE ISRAEL.'\""
        expect(verse.verse_text).to eq(expected_text)
      end

      it 'decodes &rsquo; (apostrophe)' do
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 3, verse_number: 4)
        expected_text = "Now John himself had a garment of camel's hair and a leather belt around his waist; and his food was locusts and wild honey."
        expect(verse.verse_text).to eq(expected_text)
      end
    end

    context 'idempotent behavior' do
      it 'does not create duplicate verses on multiple runs' do
        Import.call
        expect { Import.call }.not_to change { Verse.count }
      end

      it 'updates existing verses if text has changed' do
        Import.call
        
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
        original_text = verse.verse_text
        original_updated_at = verse.updated_at

        # Simulate updated text in CSV
        updated_csv = csv_content.gsub(
          'The record of the genealogy of Jesus the Messiah, the son of David, the son of Abraham:',
          'UPDATED: The record of the genealogy of Jesus the Messiah, the son of David, the son of Abraham:'
        )
        
        temp_file.open
        temp_file.write(updated_csv)
        temp_file.close

        Import.call

        verse.reload
        expect(verse.verse_text).to include('UPDATED:')
        expect(verse.updated_at).to be > original_updated_at
      end
    end

    context 'error handling' do
      it 'handles unknown book names gracefully' do
        csv_with_unknown_book = <<~CSV
          "TextID";"Version";"NT_Book";"NT_Chapter";"NT_Verse";"VerseBreak";"VerseText"
          "1";"NASB";"UnknownBook";"1";"1";"No";"Some verse text"
          "2";"NASB";"Matthew";"1";"1";"No";"Valid verse text"
        CSV

        temp_file.open
        temp_file.write(csv_with_unknown_book)
        temp_file.close

        expect { Import.call }.not_to raise_error
        expect(Verse.count).to eq(1)
        expect(Verse.first.verse_text).to eq('Valid verse text')
      end

      it 'skips rows with missing required data' do
        csv_with_missing_data = <<~CSV
          "TextID";"Version";"NT_Book";"NT_Chapter";"NT_Verse";"VerseBreak";"VerseText"
          "1";"";"Matthew";"1";"1";"No";"Missing version"
          "2";"NASB";"";"1";"1";"No";"Missing book"
          "3";"NASB";"Matthew";"1";"1";"No";""
          "4";"NASB";"Matthew";"1";"1";"No";"Valid verse"
        CSV

        temp_file.open
        temp_file.write(csv_with_missing_data)
        temp_file.close

        expect { Import.call }.not_to raise_error
        expect(Verse.count).to eq(1)
        expect(Verse.first.verse_text).to eq('Valid verse')
      end
    end

    context 'batch processing' do
      it 'processes large datasets in batches' do
        # Mock upsert_verses to track batch calls
        import_instance = Import.new
        allow(Import).to receive(:new).and_return(import_instance)
        allow(import_instance).to receive(:upsert_verses).and_call_original

        Import.call

        # Since our test data has 7 rows, it should be processed in one batch
        # But we can verify the method was called
        expect(import_instance).to have_received(:upsert_verses).at_least(:once)
      end
    end
  end

  describe 'BOOK_NAME_TO_NUMBER constant' do
    it 'maps all 66 Bible books correctly' do
      expect(Import::BOOK_NAME_TO_NUMBER).to include(
        'Genesis' => 1,
        'Matthew' => 40,
        'Revelation' => 66
      )
      expect(Import::BOOK_NAME_TO_NUMBER.keys.size).to eq(66)
    end

    it 'has unique book numbers' do
      book_numbers = Import::BOOK_NAME_TO_NUMBER.values
      expect(book_numbers.uniq.size).to eq(book_numbers.size)
    end
  end

  describe '#decode_html_entities' do
    let(:import) { Import.new }

    it 'decodes common HTML entities' do
      text = '&ldquo;Hello&rdquo; and &lsquo;world&rsquo; with &rsquo;apostrophe'
      result = import.send(:decode_html_entities, text)
      expect(result).to eq("\"Hello\" and 'world' with 'apostrophe")
    end

    it 'handles text without HTML entities' do
      text = 'Plain text without entities'
      result = import.send(:decode_html_entities, text)
      expect(result).to eq(text)
    end

    it 'handles blank text' do
      expect(import.send(:decode_html_entities, nil)).to be_nil
      expect(import.send(:decode_html_entities, '')).to eq('')
      expect(import.send(:decode_html_entities, '   ')).to eq('   ')
    end

    it 'decodes other common HTML entities' do
      text = '&amp; &lt; &gt; &quot; &#39;'
      result = import.send(:decode_html_entities, text)
      expect(result).to eq('& < > " \'')
    end
  end
end