module ChallengeCreation
  extend ActiveSupport::Concern

  private

  def load_bible_books
    bible_structure = YAML.load_file(Rails.root.join("db", "bible_structure.yml"))
    books = []

    bible_structure.each_with_index do |(book_key, chapters), index|
      book_number = index + 1
      book_name = I18n.t("bible_books.#{book_key}")
      testament = book_number <= 39 ? "old" : "new"

      books << {
        number: book_number,
        key: book_key,
        name: book_name,
        chapters: chapters,
        testament: testament
      }
    end

    books
  end

  def calculate_total_chapters(selected_books)
    return 0 unless selected_books.present?

    total_chapters = 0
    bible_structure = YAML.load_file(Rails.root.join("db", "bible_structure.yml"))

    selected_books.each do |book_number|
      book_number = book_number.to_i
      book_key = @bible_books[book_number - 1][:key]
      chapters = bible_structure[book_key.to_s]
      total_chapters += chapters
    end

    total_chapters
  end

  def calculate_schedule_end_date(start_date, total_chapters, chapters_per_day: 1, skip_days_of_week: [], skip_dates: [])
    return start_date if total_chapters.to_i <= 0 || start_date.blank?

    chapters_per_day = chapters_per_day.to_i
    chapters_per_day = 1 if chapters_per_day < 1

    skip_days = Array(skip_days_of_week).map(&:to_i)
    skip_d = Array(skip_dates).map { |d| d.is_a?(Date) ? d : (Date.parse(d.to_s) rescue nil) }.compact

    current_date = start_date.to_date
    remaining_chapters = total_chapters.to_i
    last_date = current_date

    while remaining_chapters > 0
      if skip_days.include?(current_date.wday) || skip_d.include?(current_date)
        current_date += 1.day
        next
      end

      remaining_chapters -= chapters_per_day
      last_date = current_date
      current_date += 1.day if remaining_chapters > 0
    end

    last_date
  end

  def create_readings_for_challenge(challenge, selected_books)
    return unless selected_books.present?

    # Prepare chapters in canonical book order
    chapters_to_schedule = []
    bible_structure = YAML.load_file(Rails.root.join("db", "bible_structure.yml"))

    selected_books.map(&:to_i).sort.each do |book_number|
      book_key = @bible_books[book_number - 1][:key]
      chapter_count = bible_structure[book_key.to_s]
      (1..chapter_count).each do |chapter_num|
        chapters_to_schedule << { book_number: book_number, chapter_number: chapter_num }
      end
    end

    chapters_per_day = (challenge.chapters_per_day.presence || 1).to_i
    chapters_per_day = 1 if chapters_per_day < 1

    skip_days_of_week = challenge.skip_days_of_week_list
    skip_dates = challenge.skip_dates_list

    current_date = challenge.start_date
    last_scheduled_date = current_date

    until chapters_to_schedule.empty?
      if skip_days_of_week.include?(current_date.wday) || skip_dates.include?(current_date)
        current_date += 1.day
        next
      end

      batch = chapters_to_schedule.shift(chapters_per_day)
      batch.each do |ch|
        Reading.create!(
          challenge: challenge,
          scheduled_date: current_date,
          book_number: ch[:book_number],
          chapter_number: ch[:chapter_number]
        )
      end
      last_scheduled_date = current_date
      current_date += 1.day unless chapters_to_schedule.empty?
    end

    # Sync end_date with last scheduled reading
    if last_scheduled_date.present? && challenge.end_date != last_scheduled_date
      challenge.update_column(:end_date, last_scheduled_date)
    end
  end

  def challenge_params
    permitted = params.require(:challenge).permit(
      :title, :name, :description, :start_date, :timezone, :hidden, :message_of_the_day,
      :chapters_per_day, reading_days: [], skip_days_of_week: [], skip_dates: []
    )

    if params[:challenge][:reading_days].present?
      reading_days = params[:challenge][:reading_days].reject(&:blank?).map(&:to_i)
      all_days = [ 0, 1, 2, 3, 4, 5, 6 ]
      permitted[:skip_days_of_week] = all_days - reading_days
      permitted.delete(:reading_days)
    elsif permitted[:skip_days_of_week].present?
      permitted[:skip_days_of_week] = permitted[:skip_days_of_week].reject(&:blank?).map(&:to_i)
    end

    if params[:challenge][:skip_dates_text].present?
      dates = params[:challenge][:skip_dates_text].split(/[\n,;]+/).map(&:strip).reject(&:blank?)
      parsed_dates = dates.map { |d| (Date.parse(d) rescue nil) }.compact.map(&:to_s)
      permitted[:skip_dates] = parsed_dates
    elsif params[:challenge].key?(:skip_dates_text)
      permitted[:skip_dates] = []
    end

    permitted
  end
end
