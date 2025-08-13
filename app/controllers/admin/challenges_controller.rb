class Admin::ChallengesController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def new
    @challenge = Challenge.new
    @bible_books = load_bible_books
  end

  def create
    @challenge = Challenge.new(challenge_params)
    @bible_books = load_bible_books

    # Calculate end_date before saving
    if params[:selected_books].present?
      total_chapters = calculate_total_chapters(params[:selected_books])
      @challenge.end_date = @challenge.start_date + (total_chapters - 1).days
    else
      @challenge.end_date = @challenge.start_date # No books selected
    end

    if @challenge.save
      create_readings_for_challenge(@challenge, params[:selected_books])
      redirect_to root_path, notice: 'Challenge created successfully!'
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def challenge_params
    params.require(:challenge).permit(:name, :start_date, :timezone)
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
  end

  def load_bible_books
    bible_structure = YAML.load_file(Rails.root.join('db', 'bible_structure.yml'))
    books = []
    
    bible_structure.each_with_index do |(book_key, chapters), index|
      book_number = index + 1
      book_name = I18n.t("bible_books.#{book_key}")
      testament = book_number <= 39 ? 'old' : 'new'
      
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
    bible_structure = YAML.load_file(Rails.root.join('db', 'bible_structure.yml'))
    
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

    # Create readings
    selected_books.sort_by(&:to_i).each do |book_number|
      book_number = book_number.to_i
      book_key = @bible_books[book_number - 1][:key]
      bible_structure = YAML.load_file(Rails.root.join('db', 'bible_structure.yml'))
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
end