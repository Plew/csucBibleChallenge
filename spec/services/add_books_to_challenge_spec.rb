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
    context 'when adding books 41-66 (Mark through Revelation) to a challenge with only Matthew' do
      before do
        # Create readings for Matthew (book 40, 28 chapters)
        (1..28).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 40,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end
      end

      it 'successfully adds all chapters from Mark through Revelation' do
        service = described_class.new(challenge)
        result = service.call(41, 66)

        expect(result).to be true
        expect(service.errors).to be_empty
      end

      it 'creates readings starting the day after the last Matthew reading' do
        service = described_class.new(challenge)
        service.call(41, 66)

        # Matthew ends on day 27 (chapter 28, zero-indexed), so Mark should start on day 28
        first_mark_reading = challenge.readings.find_by(book_number: 41, chapter_number: 1)
        expect(first_mark_reading.scheduled_date).to eq(start_date + 28.days)
      end

      it 'creates the correct number of readings for each book' do
        service = described_class.new(challenge)
        service.call(41, 66)

        # Mark has 16 chapters
        expect(challenge.readings.where(book_number: 41).count).to eq(16)

        # Luke has 24 chapters
        expect(challenge.readings.where(book_number: 42).count).to eq(24)

        # Revelation has 22 chapters
        expect(challenge.readings.where(book_number: 66).count).to eq(22)
      end

      it 'schedules readings consecutively without gaps' do
        service = described_class.new(challenge)
        service.call(41, 66)

        all_readings = challenge.readings.order(:scheduled_date)
        dates = all_readings.pluck(:scheduled_date)

        # Check that each date is one day after the previous
        dates.each_cons(2) do |date1, date2|
          expect(date2).to eq(date1 + 1.day)
        end
      end

      it 'updates the challenge end_date to match the last scheduled reading' do
        service = described_class.new(challenge)
        original_end_date = challenge.end_date

        service.call(41, 66)
        challenge.reload

        # Calculate expected total chapters: Matthew (28) + Mark-Revelation (233)
        # Total: 28 + 233 = 261 chapters
        # Day 0 = Jan 1, Day 260 = Sep 18
        expected_total_days = 28 + 233 - 1 # Subtract 1 because day 0 is the first day
        expected_end_date = start_date + expected_total_days.days

        expect(challenge.end_date).to eq(expected_end_date)
        expect(challenge.end_date).to be > original_end_date
      end

      it 'maintains correct book and chapter sequence' do
        service = described_class.new(challenge)
        service.call(41, 66)

        # Check Mark (book 41) has chapters 1-16
        mark_readings = challenge.readings.where(book_number: 41).order(:chapter_number)
        expect(mark_readings.pluck(:chapter_number)).to eq((1..16).to_a)

        # Check Philemon (book 57) has only chapter 1
        philemon_readings = challenge.readings.where(book_number: 57).order(:chapter_number)
        expect(philemon_readings.pluck(:chapter_number)).to eq([1])

        # Check Revelation (book 66) has chapters 1-22
        revelation_readings = challenge.readings.where(book_number: 66).order(:chapter_number)
        expect(revelation_readings.pluck(:chapter_number)).to eq((1..22).to_a)
      end

      it 'creates readings in the correct order across book boundaries' do
        service = described_class.new(challenge)
        service.call(41, 66)

        # Find the last chapter of Mark and first chapter of Luke
        last_mark = challenge.readings.find_by(book_number: 41, chapter_number: 16)
        first_luke = challenge.readings.find_by(book_number: 42, chapter_number: 1)

        expect(first_luke.scheduled_date).to eq(last_mark.scheduled_date + 1.day)
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

      it 'adds only the specified book when end_book is not provided' do
        service = described_class.new(challenge)
        result = service.call(41) # Add only Mark

        expect(result).to be true
        expect(challenge.readings.where(book_number: 41).count).to eq(16)
        expect(challenge.readings.where(book_number: 42).count).to eq(0)
      end

      it 'adds only the specified book when start and end are the same' do
        service = described_class.new(challenge)
        result = service.call(41, 41) # Add only Mark

        expect(result).to be true
        expect(challenge.readings.where(book_number: 41).count).to eq(16)
        expect(challenge.readings.where(book_number: 42).count).to eq(0)
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

      it 'returns false and sets error for invalid book range (too low)' do
        service = described_class.new(challenge)
        result = service.call(0, 10)

        expect(result).to be false
        expect(service.errors).to include(/Invalid book range/)
      end

      it 'returns false and sets error for invalid book range (too high)' do
        service = described_class.new(challenge)
        result = service.call(65, 67)

        expect(result).to be false
        expect(service.errors).to include(/Invalid book range/)
      end

      it 'returns false and sets error when start_book > end_book' do
        service = described_class.new(challenge)
        result = service.call(45, 44)

        expect(result).to be false
        expect(service.errors).to include(/Invalid book range/)
      end

      it 'returns false and sets error when challenge has no existing readings' do
        empty_challenge = create(:challenge, creator: user, start_date: start_date, end_date: start_date + 30.days)
        service = described_class.new(empty_challenge)
        result = service.call(41, 42)

        expect(result).to be false
        expect(service.errors).to include(/no existing readings/)
      end

      it 'rolls back all changes if an error occurs' do
        service = described_class.new(challenge)

        # Stub to cause a failure mid-transaction
        allow_any_instance_of(Reading).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Reading.new))

        expect {
          service.call(41, 42)
        }.not_to change { challenge.readings.count }

        expect(service.errors).not_to be_empty
      end
    end

    context 'with different starting scenarios' do
      it 'works when the last reading is not on a chapter 1' do
        # Create partial Genesis readings (chapters 1-5)
        (1..5).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 1,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end

        service = described_class.new(challenge)
        result = service.call(40, 40) # Add Matthew

        expect(result).to be true
        first_matthew = challenge.readings.find_by(book_number: 40, chapter_number: 1)
        expect(first_matthew.scheduled_date).to eq(start_date + 5.days)
      end

      it 'works with non-consecutive book additions' do
        # Add Matthew
        (1..28).each do |chapter|
          create(:reading,
                 challenge: challenge,
                 book_number: 40,
                 chapter_number: chapter,
                 scheduled_date: start_date + (chapter - 1).days)
        end

        # Add Mark
        service = described_class.new(challenge)
        service.call(41, 41)

        # Add Luke (skipping directly)
        challenge.reload
        service2 = described_class.new(challenge)
        service2.call(42, 42)

        expect(challenge.readings.where(book_number: 41).count).to eq(16)
        expect(challenge.readings.where(book_number: 42).count).to eq(24)

        last_mark = challenge.readings.where(book_number: 41).order(:scheduled_date).last
        first_luke = challenge.readings.where(book_number: 42).order(:scheduled_date).first
        expect(first_luke.scheduled_date).to eq(last_mark.scheduled_date + 1.day)
      end
    end
  end

  describe 'BIBLE_STRUCTURE constant' do
    it 'contains all 66 books' do
      expect(described_class::BIBLE_STRUCTURE.keys.sort).to eq((1..66).to_a)
    end

    it 'has correct chapter counts for New Testament books' do
      expect(described_class::BIBLE_STRUCTURE[40]).to eq(28) # Matthew
      expect(described_class::BIBLE_STRUCTURE[41]).to eq(16) # Mark
      expect(described_class::BIBLE_STRUCTURE[57]).to eq(1)  # Philemon
      expect(described_class::BIBLE_STRUCTURE[66]).to eq(22) # Revelation
    end
  end
end
