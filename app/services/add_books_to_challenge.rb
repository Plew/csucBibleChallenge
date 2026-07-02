# Service class to add Bible books (as readings) to an existing challenge
# Books are added sequentially, following the last scheduled reading in the challenge
#
# Usage:
#   AddBooksToChallenge.new(challenge).call([ 41, 44, 66 ]) # Adds Mark, Acts, and Revelation
#   AddBooksToChallenge.new(challenge).call([ 41 ])          # Adds only Mark
#
class AddBooksToChallenge
  attr_reader :challenge, :errors

  def initialize(challenge)
    @challenge = challenge
    @errors = []
  end

  # Adds the given books to the challenge, in canonical book order.
  #
  # @param book_numbers [Array<Integer>] The book numbers to add (1-66)
  # @return [Boolean] true if successful, false otherwise
  def call(book_numbers)
    book_numbers = Array(book_numbers).map(&:to_i).uniq

    unless valid_book_numbers?(book_numbers)
      @errors << "Invalid book selection. Books must be between 1-66."
      return false
    end

    duplicate_books = book_numbers & challenge.readings.distinct.pluck(:book_number)
    if duplicate_books.any?
      book_names = duplicate_books.sort.map { |number| BibleBooks.name_for(number) }.join(", ")
      @errors << "Challenge already contains: #{book_names}."
      return false
    end

    last_reading = challenge.readings.order(:scheduled_date).last
    unless last_reading
      @errors << "Challenge has no existing readings. Cannot determine start date."
      return false
    end

    # Start scheduling the day after the last reading
    next_date = last_reading.scheduled_date + 1.day

    ActiveRecord::Base.transaction do
      book_numbers.sort.each do |book_number|
        chapter_count = chapter_counts[book_number]

        (1..chapter_count).each do |chapter_number|
          challenge.readings.create!(
            book_number: book_number,
            chapter_number: chapter_number,
            scheduled_date: next_date
          )
          next_date += 1.day
        end
      end

      # Update challenge end_date to match the last scheduled reading
      new_end_date = challenge.readings.order(:scheduled_date).last.scheduled_date
      challenge.update!(end_date: new_end_date)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Failed to add readings: #{e.message}"
    false
  end

  private

  def valid_book_numbers?(book_numbers)
    book_numbers.present? && book_numbers.all? { |number| number.between?(1, 66) }
  end

  # Book number (1-66) => chapter count, sourced from the same bible_structure.yml
  # that challenge creation uses, in canonical book order.
  def chapter_counts
    @chapter_counts ||= YAML.load_file(Rails.root.join("db", "bible_structure.yml"))
      .values.each_with_index.to_h { |chapters, index| [ index + 1, chapters ] }
  end
end
