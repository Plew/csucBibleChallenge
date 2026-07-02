# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddBooksToChallenge, type: :service do
  let(:user) { create(:user, admin: true) }
  let(:start_date) { Date.new(2025, 1, 1) }
  let(:challenge) do
    create(:challenge,
           creator: user,
           name: "New Testament Challenge",
           start_date: start_date,
           end_date: start_date + 27.days, # Matthew has 28 chapters
           timezone: "UTC")
  end

  describe '#call' do
    context 'when adding an arbitrary set of books (Ruth, Jonah, Jude) to a challenge with only Matthew' do
      before do
        (1..28).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 40,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end
      end

      it 'successfully adds the selected books' do
        service = described_class.new(challenge)
        result = service.call([ 65, 8, 32 ]) # Jude, Ruth, Jonah (unordered)

        expect(result).to be true
        expect(service.errors).to be_empty
      end

      it 'creates the correct number of readings for each book' do
        service = described_class.new(challenge)
        service.call([ 65, 8, 32 ])

        expect(challenge.readings.where(book_number: 8).count).to eq(4)  # Ruth
        expect(challenge.readings.where(book_number: 32).count).to eq(4) # Jonah
        expect(challenge.readings.where(book_number: 65).count).to eq(1) # Jude
      end

      it 'appends the books in canonical book order regardless of input order' do
        service = described_class.new(challenge)
        service.call([ 65, 8, 32 ]) # passed as Jude, Ruth, Jonah

        # Canonical order: Ruth (8), Jonah (32), Jude (65)
        first_ruth = challenge.readings.find_by(book_number: 8, chapter_number: 1)
        last_ruth = challenge.readings.find_by(book_number: 8, chapter_number: 4)
        first_jonah = challenge.readings.find_by(book_number: 32, chapter_number: 1)
        last_jonah = challenge.readings.find_by(book_number: 32, chapter_number: 4)
        jude = challenge.readings.find_by(book_number: 65, chapter_number: 1)

        expect(first_ruth.scheduled_date).to eq(start_date + 28.days)
        expect(first_jonah.scheduled_date).to eq(last_ruth.scheduled_date + 1.day)
        expect(jude.scheduled_date).to eq(last_jonah.scheduled_date + 1.day)
      end

      it 'schedules readings consecutively without gaps' do
        service = described_class.new(challenge)
        service.call([ 65, 8, 32 ])

        dates = challenge.readings.order(:scheduled_date).pluck(:scheduled_date)

        dates.each_cons(2) do |date1, date2|
          expect(date2).to eq(date1 + 1.day)
        end
      end

      it 'updates the challenge end_date to match the last scheduled reading' do
        service = described_class.new(challenge)
        original_end_date = challenge.end_date

        service.call([ 65, 8, 32 ])
        challenge.reload

        last_reading = challenge.readings.order(:scheduled_date).last
        expect(challenge.end_date).to eq(last_reading.scheduled_date)
        expect(challenge.end_date).to be > original_end_date
      end
    end

    context 'when adding a single book' do
      before do
        create(:reading,
               challenge: challenge,
               book_number: 40,
               chapter_number: 1,
               scheduled_date: start_date)
      end

      it 'adds only the specified book' do
        service = described_class.new(challenge)
        result = service.call([ 41 ]) # Add only Mark

        expect(result).to be true
        expect(challenge.readings.where(book_number: 41).count).to eq(16)
        expect(challenge.readings.where(book_number: 42).count).to eq(0)
      end

      it 'de-duplicates a book number passed more than once' do
        service = described_class.new(challenge)
        result = service.call([ 41, 41 ])

        expect(result).to be true
        expect(challenge.readings.where(book_number: 41).count).to eq(16)
      end
    end

    context 'validation and error handling' do
      before do
        create(:reading,
               challenge: challenge,
               book_number: 40,
               chapter_number: 1,
               scheduled_date: start_date)
      end

      it 'returns false and sets error for an out-of-range book number (too low)' do
        service = described_class.new(challenge)
        result = service.call([ 0, 10 ])

        expect(result).to be false
        expect(service.errors).to include(/Invalid book selection/)
      end

      it 'returns false and sets error for an out-of-range book number (too high)' do
        service = described_class.new(challenge)
        result = service.call([ 41, 67 ])

        expect(result).to be false
        expect(service.errors).to include(/Invalid book selection/)
      end

      it 'returns false and sets error when no books are given' do
        service = described_class.new(challenge)
        result = service.call([])

        expect(result).to be false
        expect(service.errors).to include(/Invalid book selection/)
      end

      it 'returns false and names the offending book(s) already in the challenge, persisting nothing' do
        service = described_class.new(challenge)

        expect {
          result = service.call([ 40, 41 ]) # Matthew is already present
          expect(result).to be false
          expect(service.errors).to include(/Matthew/)
        }.not_to change { challenge.readings.count }
      end

      it 'returns false and sets error when challenge has no existing readings' do
        empty_challenge = create(:challenge, creator: user, start_date: start_date, end_date: start_date + 30.days)
        service = described_class.new(empty_challenge)
        result = service.call([ 41, 42 ])

        expect(result).to be false
        expect(service.errors).to include(/no existing readings/)
      end

      it 'rolls back all changes if an error occurs' do
        service = described_class.new(challenge)

        allow_any_instance_of(Reading).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Reading.new))

        expect {
          service.call([ 41, 42 ])
        }.not_to change { challenge.readings.count }

        expect(service.errors).not_to be_empty
      end
    end

    context 'with different starting scenarios' do
      it 'works when the last reading is not on a chapter 1' do
        (1..5).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 1,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end

        service = described_class.new(challenge)
        result = service.call([ 40 ]) # Add Matthew

        expect(result).to be true
        first_matthew = challenge.readings.find_by(book_number: 40, chapter_number: 1)
        expect(first_matthew.scheduled_date).to eq(start_date + 5.days)
      end

      it 'works with non-consecutive book additions across separate calls' do
        (1..28).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 40,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end

        service = described_class.new(challenge)
        service.call([ 41 ]) # Add Mark

        challenge.reload
        service2 = described_class.new(challenge)
        service2.call([ 42 ]) # Add Luke

        expect(challenge.readings.where(book_number: 41).count).to eq(16)
        expect(challenge.readings.where(book_number: 42).count).to eq(24)

        last_mark = challenge.readings.where(book_number: 41).order(:scheduled_date).last
        first_luke = challenge.readings.where(book_number: 42).order(:scheduled_date).first
        expect(first_luke.scheduled_date).to eq(last_mark.scheduled_date + 1.day)
      end
    end
  end

  describe '#preview' do
    before do
      (1..28).each do |chapter|
        create(:reading,
               challenge: challenge,
               book_number: 40,
               chapter_number: chapter,
               scheduled_date: start_date + (chapter - 1).days)
      end
    end

    it 'returns the total chapter count and new end date without persisting anything' do
      service = described_class.new(challenge)

      expect {
        result = service.preview([ 41 ]) # Mark, 16 chapters

        expect(result).to eq(total_chapters: 16, new_end_date: challenge.end_date + 16.days)
      }.not_to change { challenge.readings.count }

      expect(challenge.reload.end_date).to eq(start_date + 27.days)
    end

    it 'sums chapters across multiple selected books' do
      service = described_class.new(challenge)

      result = service.preview([ 41, 42 ]) # Mark (16) + Luke (24)

      expect(result[:total_chapters]).to eq(40)
      expect(result[:new_end_date]).to eq(challenge.end_date + 40.days)
    end

    it 'returns nil for an invalid book number' do
      service = described_class.new(challenge)

      expect(service.preview([ 0 ])).to be_nil
      expect(service.preview([ 67 ])).to be_nil
    end

    it 'returns nil when no books are given' do
      service = described_class.new(challenge)

      expect(service.preview([])).to be_nil
    end

    it 'returns nil when a selected book is already in the challenge' do
      service = described_class.new(challenge)

      expect(service.preview([ 40, 41 ])).to be_nil
    end

    it 'returns nil when the challenge has no existing readings' do
      empty_challenge = create(:challenge, creator: user, start_date: start_date, end_date: start_date + 30.days)
      service = described_class.new(empty_challenge)

      expect(service.preview([ 41 ])).to be_nil
    end
  end

  describe 'chapter counts' do
    it 'sources chapter counts from db/bible_structure.yml, matching known values' do
      service = described_class.new(challenge)
      chapter_counts = service.send(:chapter_counts)

      expect(chapter_counts.keys.sort).to eq((1..66).to_a)
      expect(chapter_counts[1]).to eq(50)   # Genesis
      expect(chapter_counts[19]).to eq(150) # Psalms
      expect(chapter_counts[29]).to eq(3)   # Joel
      expect(chapter_counts[40]).to eq(28)  # Matthew
      expect(chapter_counts[50]).to eq(4)   # Philippians
      expect(chapter_counts[66]).to eq(22)  # Revelation
    end
  end
end
