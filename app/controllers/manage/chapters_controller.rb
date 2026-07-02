class Manage::ChaptersController < Manage::BaseController
  include ChallengeCreation

  def index
    @readings = @challenge.readings.order(:scheduled_date, :book_number, :chapter_number)
  end

  def add_books
    @bible_books = books_not_in_challenge
  end

  def create_add_books
    service = AddBooksToChallenge.new(@challenge)
    selected_books = Array(params[:selected_books]).reject(&:blank?)

    if service.call(selected_books)
      book_names = selected_books.map(&:to_i).sort.map { |number| BibleBooks.name_for(number) }.join(", ")
      redirect_to challenge_manage_chapters_path(@challenge), notice: t("manage.chapters.add_books.success", books: book_names)
    else
      @bible_books = books_not_in_challenge
      @errors = service.errors
      render :add_books, status: :unprocessable_content
    end
  end

  private

  def books_not_in_challenge
    existing_book_numbers = @challenge.readings.distinct.pluck(:book_number)
    load_bible_books.reject { |book| existing_book_numbers.include?(book[:number]) }
  end
end
