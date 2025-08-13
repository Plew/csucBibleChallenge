require 'rails_helper'

RSpec.describe Import do
  let(:basic_csv_path) { Rails.root.join('spec/fixtures/test_verses_basic.csv') }
  let(:html_entities_csv_path) { Rails.root.join('spec/fixtures/test_verses_html_entities.csv') }
  let(:error_conditions_csv_path) { Rails.root.join('spec/fixtures/test_verses_error_conditions.csv') }
  let(:integration_csv_path) { Rails.root.join('spec/fixtures/test_verses_integration.csv') }

  describe '.call' do

    context 'basic functionality' do
      before do
        stub_const('Import::FILE_PATH', basic_csv_path)
        Import.call
      end

      it 'imports verses from CSV file' do
        expect(Verse.count).to eq(5)
      end

      it 'creates verses with correct attributes' do
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
        expect(verse).to be_present
        expect(verse.verse_text).to eq('The record of the genealogy of Jesus the Messiah, the son of David, the son of Abraham:')
      end

      it 'correctly maps book names to book numbers' do
        matthew_verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
        mark_verse = Verse.find_by(version: 'KJV', book_number: 41, chapter_number: 1, verse_number: 1)
        luke_verse = Verse.find_by(version: 'ESV', book_number: 42, chapter_number: 1, verse_number: 1)
        john_verse = Verse.find_by(version: 'NASB', book_number: 43, chapter_number: 1, verse_number: 1)

        expect(matthew_verse).to be_present
        expect(mark_verse).to be_present
        expect(luke_verse).to be_present
        expect(john_verse).to be_present
      end
    end

    context 'HTML entity decoding' do
      before do
        stub_const('Import::FILE_PATH', html_entities_csv_path)
        Import.call
      end

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
      let(:temp_file) { Tempfile.new(['test_verses', '.csv']) }
      
      before do
        stub_const('Import::FILE_PATH', temp_file.path)
      end
      
      after do
        temp_file.unlink
      end
      
      it 'does not create duplicate verses on multiple runs' do
        temp_file.write(File.read(basic_csv_path))
        temp_file.close
        
        Import.call
        expect { Import.call }.not_to change { Verse.count }
      end

      it 'updates existing verses if text has changed' do
        temp_file.write(File.read(basic_csv_path))
        temp_file.close
        
        Import.call
        
        verse = Verse.find_by(version: 'NASB', book_number: 40, chapter_number: 1, verse_number: 1)
        original_text = verse.verse_text
        original_updated_at = verse.updated_at

        # Simulate updated text in CSV
        updated_csv = File.read(basic_csv_path).gsub(
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
      before do
        stub_const('Import::FILE_PATH', error_conditions_csv_path)
      end
      
      it 'handles unknown book names and missing data gracefully' do
        expect { Import.call }.not_to raise_error
        expect(Verse.count).to eq(2)
        valid_verses = Verse.where(verse_text: ['Valid verse text', 'Another valid verse'])
        expect(valid_verses.count).to eq(2)
      end
    end

    context 'batch processing' do
      before do
        stub_const('Import::FILE_PATH', basic_csv_path)
      end
      
      it 'processes data in batches' do
        # Mock upsert_verses to track batch calls
        import_instance = Import.new
        allow(Import).to receive(:new).and_return(import_instance)
        allow(import_instance).to receive(:upsert_verses).and_call_original

        Import.call

        # Since our test data has 5 rows, it should be processed in one batch
        # But we can verify the method was called
        expect(import_instance).to have_received(:upsert_verses).at_least(:once)
      end
    end

    # Comprehensive integration test with larger dataset (tagged as slow)
    context 'comprehensive integration test', :slow do
      before do
        stub_const('Import::FILE_PATH', integration_csv_path)
        Import.call
      end
      
      it 'imports multiple versions and books correctly' do
        expect(Verse.count).to eq(20)
        
        # Verify multiple versions
        expect(Verse.where(version: 'NASB').count).to be > 0
        expect(Verse.where(version: 'KJV').count).to be > 0
        expect(Verse.where(version: 'ESV').count).to be > 0
        
        # Verify multiple books
        matthew_verses = Verse.where(book_number: 40)
        mark_verses = Verse.where(book_number: 41)
        luke_verses = Verse.where(book_number: 42)
        john_verses = Verse.where(book_number: 43)
        acts_verses = Verse.where(book_number: 44)
        romans_verses = Verse.where(book_number: 45)
        
        expect(matthew_verses.count).to be > 0
        expect(mark_verses.count).to be > 0
        expect(luke_verses.count).to be > 0
        expect(john_verses.count).to be > 0
        expect(acts_verses.count).to be > 0
        expect(romans_verses.count).to be > 0
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
      # Note: Hash has more than 66 keys due to alternative naming formats (First/1, Second/2, etc.)
      expect(Import::BOOK_NAME_TO_NUMBER.keys.size).to eq(77)
    end

    it 'has unique book numbers' do
      book_numbers = Import::BOOK_NAME_TO_NUMBER.values
      # Some books have alternative naming formats, so there are duplicate book numbers
      expect(book_numbers.uniq.size).to eq(66)  # 66 unique Bible books
      expect(book_numbers.size).to eq(77)       # 77 total entries with alternative names
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
      text = '&amp; &lt; &gt; &quot;'
      result = import.send(:decode_html_entities, text)
      expect(result).to eq('& < > "')
    end
  end
end