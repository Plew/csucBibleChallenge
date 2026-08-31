require 'rails_helper'

RSpec.describe ImportMissingVersesJob, type: :job do
  describe "#perform" do
    it "runs Import.call for missing translations" do
      expect(Import).to receive(:call).at_least(:once)
      # Simulate missing KJV Genesis 1
      Verse.where(version: "KJV", book_number: 1, chapter_number: 1).delete_all
      described_class.new.perform
    end

    it "skips import if all translations already exist in database" do
      # Pre-create verse records for all 4 check versions
      %w[ESV NASB ASV KJV].each do |ver|
        Verse.find_or_create_by!(version: ver, book_number: 1, chapter_number: 1, verse_number: 1) do |v|
          v.verse_text = "In the beginning..."
        end
      end

      expect(Import).not_to receive(:call)
      described_class.new.perform
    end
  end
end
