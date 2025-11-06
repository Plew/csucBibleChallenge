class Api::V1::ChapterVersesController < Api::BaseController
  # GET /api/v1/chapter_verses?version=KJV&book_number=1&chapter_number=1
  def show
    version = params[:version]
    book_number = params[:book_number]
    chapter_number = params[:chapter_number]

    if version.blank? || book_number.blank? || chapter_number.blank?
      return render json: { errors: [ "Missing required parameters: version, book_number, and chapter_number must all be provided." ] }, status: :bad_request
    end

    # Optional: Validate numericality of book_number and chapter_number if they are not guaranteed to be integers by client
    # begin
    #   book_val = Integer(book_number)
    #   chapter_val = Integer(chapter_number)
    # rescue ArgumentError, TypeError
    #   return render json: { errors: ["book_number and chapter_number must be integers."] }, status: :bad_request
    # end

    verses = Verse.where(
      version: version,
      book_number: book_number,
      chapter_number: chapter_number
    ).order(:verse_number)

    if verses.any?
      render json: verses, status: :ok
    else
      # Return empty array if no verses found, which is a valid result for a query
      render json: [], status: :ok
      # Alternative: return 404 if specific chapter combination must exist
      # render json: { errors: ["No verses found for the specified version, book, and chapter."] }, status: :not_found
    end
  end
end
