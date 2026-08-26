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

    chapters_per_day = (challenge.chapters_per_day.presence || 1).to_i
    chapters_per_day = 1 if chapters_per_day < 1
    skip_days = challenge.skip_days_of_week_list
    skip_dates = challenge.skip_dates_list

    # Determine remaining capacity on last reading's date or move to next eligible day
    last_date_readings_count = challenge.readings.where(scheduled_date: last_reading.scheduled_date).count
    current_date = if last_date_readings_count < chapters_per_day && !skip_days.include?(last_reading.scheduled_date.wday) && !skip_dates.include?(last_reading.scheduled_date)
                     last_reading.scheduled_date
                   else
                     last_reading.scheduled_date + 1.day
                   end

    # Build queue of chapters to add
    chapters_to_add = []
    book_numbers.sort.each do |book_number|
      chapter_count = chapter_counts[book_number]
      (1..chapter_count).each do |chapter_number|
        chapters_to_add << { book_number: book_number, chapter_number: chapter_number }
      end
    end

    ActiveRecord::Base.transaction do
      until chapters_to_add.empty?
        if skip_days.include?(current_date.wday) || skip_dates.include?(current_date)
          current_date += 1.day
          next
        end

        # If on the last reading's date, only take remaining slot capacity
        slot_capacity = if current_date == last_reading.scheduled_date
                          [chapters_per_day - last_date_readings_count, 1].max
                        else
                          chapters_per_day
                        end

        batch = chapters_to_add.shift(slot_capacity)
        batch.each do |ch|
          challenge.readings.create!(
            book_number: ch[:book_number],
            chapter_number: ch[:chapter_number],
            scheduled_date: current_date
          )
        end
        current_date += 1.day unless chapters_to_add.empty?
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

  # Computes what #call would do, without persisting anything.
  #
  # @param book_numbers [Array<Integer>] The book numbers to preview (1-66)
  # @return [Hash, nil] { total_chapters:, new_end_date: }, or nil if the selection is invalid
  def preview(book_numbers)
    book_numbers = Array(book_numbers).map(&:to_i).uniq

    return nil unless valid_book_numbers?(book_numbers)
    return nil if (book_numbers & challenge.readings.distinct.pluck(:book_number)).any?

    last_reading = challenge.readings.order(:scheduled_date).last
    return nil unless last_reading

    total_chapters = book_numbers.sum { |book_number| chapter_counts[book_number] }

    chapters_per_day = (challenge.chapters_per_day.presence || 1).to_i
    chapters_per_day = 1 if chapters_per_day < 1
    skip_days = challenge.skip_days_of_week_list
    skip_dates = challenge.skip_dates_list

    last_date_readings_count = challenge.readings.where(scheduled_date: last_reading.scheduled_date).count
    current_date = if last_date_readings_count < chapters_per_day && !skip_days.include?(last_reading.scheduled_date.wday) && !skip_dates.include?(last_reading.scheduled_date)
                     last_reading.scheduled_date
                   else
                     last_reading.scheduled_date + 1.day
                   end

    remaining = total_chapters
    last_date = current_date
    first_pass = true

    while remaining > 0
      if skip_days.include?(current_date.wday) || skip_dates.include?(current_date)
        current_date += 1.day
        next
      end

      slot = if first_pass && current_date == last_reading.scheduled_date
               [chapters_per_day - last_date_readings_count, 1].max
             else
               chapters_per_day
             end
      first_pass = false

      remaining -= slot
      last_date = current_date
      current_date += 1.day if remaining > 0
    end

    { total_chapters: total_chapters, new_end_date: last_date }
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
