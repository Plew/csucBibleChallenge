require 'rails_helper'

RSpec.describe VerseFetcher do
  describe ".fetch_with_version" do
    before do
      # Create Old Testament verses (Genesis 1) in multiple versions
      Verse.find_or_create_by!(version: 'ELB2006', book_number: 1, chapter_number: 1, verse_number: 1) do |v|
        v.verse_text = "Im Anfang schuf Gott die Himmel und die Erde."
      end

      Verse.find_or_create_by!(version: 'SCHL2000', book_number: 1, chapter_number: 1, verse_number: 1) do |v|
        v.verse_text = "Im Anfang schuf Gott die Himmel und die Erde."
      end

      Verse.find_or_create_by!(version: 'ESV', book_number: 1, chapter_number: 1, verse_number: 1) do |v|
        v.verse_text = "In the beginning, God created the heavens and the earth."
      end

      Verse.find_or_create_by!(version: 'NASB', book_number: 1, chapter_number: 1, verse_number: 1) do |v|
        v.verse_text = "In the beginning God created the heavens and the earth."
      end
    end

    context "when user requests ESV" do
      it "returns ESV verses" do
        result = described_class.fetch_with_version(version: "ESV", book_number: 1, chapter_number: 1)
        expect(result[:version]).to eq("ESV")
        expect(result[:verses].first.verse_text).to include("In the beginning")
      end
    end

    context "when user requests KJV but KJV is missing for this chapter" do
      it "falls back to an English version (ESV), never German" do
        result = described_class.fetch_with_version(version: "KJV", book_number: 1, chapter_number: 1)
        expect(result[:version]).to eq("ESV")
        expect(result[:verses].first.verse_text).to include("In the beginning")
        expect(result[:verses].first.verse_text).not_to include("Im Anfang")
      end
    end

    context "when user requests RCV and API is not configured or returns nil" do
      before do
        allow_any_instance_of(RecoveryVersionClient).to receive(:fetch_chapter).and_return(nil)
      end

      it "falls back to an English version (ESV), never German" do
        result = described_class.fetch_with_version(version: "RCV", book_number: 1, chapter_number: 1)
        expect(result[:version]).to eq("ESV")
        expect(result[:verses].first.verse_text).to include("In the beginning")
        expect(result[:verses].first.verse_text).not_to include("Im Anfang")
      end
    end

    context "when user requests German (ELB2006)" do
      it "returns German verses" do
        result = described_class.fetch_with_version(version: "ELB2006", book_number: 1, chapter_number: 1)
        expect(result[:version]).to eq("ELB2006")
        expect(result[:verses].first.verse_text).to include("Im Anfang")
      end
    end

    context "when user requests German (SCHL2000)" do
      it "returns Schlachter 2000 verses" do
        result = described_class.fetch_with_version(version: "SCHL2000", book_number: 1, chapter_number: 1)
        expect(result[:version]).to eq("SCHL2000")
        expect(result[:verses].first.verse_text).to include("Im Anfang")
      end
    end

    context "when only German exists in database and user requests English" do
      before do
        Verse.where(book_number: 2, chapter_number: 1).delete_all
        Verse.create!(version: 'ELB2006', book_number: 2, chapter_number: 1, verse_number: 1, verse_text: "Dies sind die Namen")
      end

      it "falls back gracefully without crashing" do
        result = described_class.fetch_with_version(version: "ESV", book_number: 2, chapter_number: 1)
        expect(result[:verses]).to be_present
      end
    end
  end
end
