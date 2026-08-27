class Admin::ChallengesController < Admin::BaseController
  include ChallengeCreation

  before_action :set_challenge, only: [ :delete_confirmation, :destroy ]
  before_action :ensure_creator, only: [ :delete_confirmation, :destroy ]

  def index
    @challenges = Challenge.includes(:creator, :user_challenge_enrollments).order(created_at: :desc)
  end

  def new
    @challenge = Challenge.new
    @bible_books = load_bible_books
  end

  def create
    @challenge = Challenge.new(challenge_params)
    @challenge.creator = current_user
    @bible_books = load_bible_books

    # Calculate end_date before saving
    if params[:selected_books].present? && @challenge.start_date.present?
      total_chapters = calculate_total_chapters(params[:selected_books])
      @challenge.end_date = calculate_schedule_end_date(
        @challenge.start_date,
        total_chapters,
        chapters_per_day: @challenge.chapters_per_day,
        skip_days_of_week: @challenge.skip_days_of_week,
        skip_dates: @challenge.skip_dates
      )
    else
      @challenge.end_date = @challenge.start_date # No books selected
    end

    if @challenge.save
      create_readings_for_challenge(@challenge, params[:selected_books])
      redirect_to root_path, notice: "Challenge created successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def delete_confirmation
    # @challenge is set by before_action
  end

  def destroy
    if params[:confirmation_text] != "i want this"
      redirect_to delete_confirmation_admin_challenge_path(@challenge),
                  alert: 'Confirmation text is incorrect. Please type "i want this" exactly.'
      return
    end

    session.delete(:active_challenge_id) if session[:active_challenge_id] == @challenge.id
    @challenge.destroy
    redirect_to root_path, notice: "Challenge deleted successfully."
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:id])
  end

  def ensure_creator
    unless @challenge.owned_by?(current_user)
      redirect_to root_path, alert: "You can only delete challenges you created."
    end
  end
end
