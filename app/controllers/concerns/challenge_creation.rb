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

  def create_readings_for_challenge(challenge, selected_books)
    return unless selected_books.present?

    current_date = challenge.start_date

    selected_books.sort_by(&:to_i).each do |book_number|
      book_number = book_number.to_i
      book_key = @bible_books[book_number - 1][:key]
      bible_structure = YAML.load_file(Rails.root.join("db", "bible_structure.yml"))
      chapters = bible_structure[book_key.to_s]

      (1..chapters).each do |chapter|
        Reading.create!(
          challenge: challenge,
          scheduled_date: current_date,
          book_number: book_number,
          chapter_number: chapter
        )
        current_date += 1.day
      end
    end
  end

  def challenge_params
    params.require(:challenge).permit(:title, :name, :description, :start_date, :timezone, :hidden, :message_of_the_day)
  end
end
