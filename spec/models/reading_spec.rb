require 'rails_helper'

RSpec.describe Reading, type: :model do
  describe 'associations' do
    it { should belong_to(:challenge) }
    it { should have_many(:user_readings).dependent(:destroy) }
    it { should have_many(:completed_by_users).through(:user_readings).source(:user) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:reading) } # Use FactoryBot

    it { should validate_presence_of(:scheduled_date) }
    it { should validate_presence_of(:book_number) }
    it { should validate_numericality_of(:book_number).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:chapter_number) }
    it { should validate_numericality_of(:chapter_number).only_integer.is_greater_than(0) }
    # Presence of challenge is implicitly tested by `belong_to` matcher
  end

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:reading)).to be_valid # build should be fine if challenge is created by factory
  end

  it 'is invalid without a scheduled_date' do
    reading = FactoryBot.build(:reading, scheduled_date: nil)
    expect(reading).not_to be_valid
    expect(reading.errors[:scheduled_date]).to include("can't be blank")
  end

  it 'is invalid without a challenge' do
    reading = FactoryBot.build(:reading, challenge: nil)
    expect(reading).not_to be_valid
    expect(reading.errors[:challenge]).to include("must exist")
  end

  describe '#verses' do
    let(:challenge) { FactoryBot.create(:challenge) } # Assuming you have a challenge factory
    let(:reading) { FactoryBot.create(:reading, challenge: challenge, book_number: 1, chapter_number: 1) }

    # Assuming you have a :verse factory that takes :version, :book_number, :chapter_number, :verse_number, :verse_text
    let!(:verse1_kjv) { FactoryBot.create(:verse, version: 'KJV', book_number: 1, chapter_number: 1, verse_number: 1, verse_text: 'In the beginning...') }
    let!(:verse2_kjv) { FactoryBot.create(:verse, version: 'KJV', book_number: 1, chapter_number: 1, verse_number: 2, verse_text: 'And God said...') }
    let!(:other_chapter_verse_kjv) { FactoryBot.create(:verse, version: 'KJV', book_number: 1, chapter_number: 2, verse_number: 1, verse_text: 'Another chapter...') }
    let!(:other_book_verse_kjv) { FactoryBot.create(:verse, version: 'KJV', book_number: 2, chapter_number: 1, verse_number: 1, verse_text: 'Another book...') }
    let!(:verse1_niv) { FactoryBot.create(:verse, version: 'NIV', book_number: 1, chapter_number: 1, verse_number: 1, verse_text: 'In the beginning NIV...') }

    context 'when no version is specified' do
      it 'returns verses for the reading\'s book and chapter in KJV, ordered by verse_number' do
        expect(reading.verses).to eq([verse1_kjv, verse2_kjv])
      end
    end

    context 'when a version is specified' do
      it 'returns verses for that version, book, and chapter, ordered by verse_number' do
        expect(reading.verses(version: 'NIV')).to eq([verse1_niv])
      end
    end

    context 'when no matching verses exist' do
      let(:reading_no_verses) { FactoryBot.create(:reading, challenge: challenge, book_number: 99, chapter_number: 99) }
      it 'returns an empty collection' do
        expect(reading_no_verses.verses).to be_empty
      end
    end

    context 'when verses are out of order in the database' do
      let!(:verse3_kjv_earlier) { FactoryBot.create(:verse, version: 'KJV', book_number: 1, chapter_number: 1, verse_number: 3, verse_text: 'A later verse created earlier') }
      before do
        # Ensure verse2_kjv is created after verse3_kjv_earlier to test ordering
        verse2_kjv.save! # Re-save or ensure creation order if DB assigns IDs sequentially that affect default order
      end
      it 'still returns them ordered by verse_number' do
        # Re-fetch verse2_kjv if its ID or creation timestamp matters for default DB order before our explicit order
        # For this test, we rely on the .order(:verse_number) in the method.
        expect(reading.verses).to eq([verse1_kjv, verse2_kjv, verse3_kjv_earlier])
      end
    end
  end
end
