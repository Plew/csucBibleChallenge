class ChallengesController < ApplicationController
  include ChallengeCreation

  before_action :require_login, only: [ :new, :create ]
  before_action :require_challenge_creator, only: [ :new, :create ]

  # GET /challenges
  def index
    # Show simple list of active and upcoming challenges
    @challenges = Challenge.where("end_date >= ? AND hidden = ?", Date.current, false)
                          .includes(:users, :groups, :readings)
  end

  # GET /challenges/:id
  def show
    @challenge = Challenge.find(params[:id])
    @user_count = @challenge.users.count
    @participants = @challenge.user_challenge_enrollments.includes(:user).order(created_at: :desc).map(&:user)
    @most_recent_user = @challenge.user_challenge_enrollments.includes(:user).order(created_at: :desc).first&.user
    @most_recent_join_time = @challenge.user_challenge_enrollments.order(created_at: :desc).first&.created_at
    @challenge_readings = @challenge.readings.order(:scheduled_date)
    @books_and_chapters = @challenge_readings.group_by(&:book_number).transform_values { |readings| readings.map(&:chapter_number) }
    @user_enrollment = current_user&.user_challenge_enrollments&.find_by(challenge: @challenge)

    # Get user's group if they're in one
    @user_group = current_user&.groups&.where(challenge_id: @challenge.id)&.first

    # Sort groups with user's group first
    all_groups = @challenge.groups.includes(:users).order(:name)
    @groups = if @user_group
      [ all_groups.find { |g| g.id == @user_group.id } ].compact + all_groups.where.not(id: @user_group.id)
    else
      all_groups
    end
  end

  # GET /challenges/new
  def new
    @challenge = Challenge.new(hidden: true, start_date: Date.tomorrow)
    @bible_books = load_bible_books
  end

  # POST /challenges
  def create
    @challenge = Challenge.new(challenge_params)
    @challenge.creator = current_user
    @challenge.hidden = true
    @bible_books = load_bible_books

    # Calculate end_date before saving
    if params[:selected_books].present?
      total_chapters = calculate_total_chapters(params[:selected_books])
      @challenge.end_date = @challenge.start_date + (total_chapters - 1).days
    else
      @challenge.end_date = @challenge.start_date
    end

    if @challenge.save
      create_readings_for_challenge(@challenge, params[:selected_books])
      @challenge.user_challenge_enrollments.create!(user: current_user, role: "organizer")
      redirect_to challenge_manage_dashboard_path(@challenge), notice: t("manage.challenge_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  # GET /challenges/:id/summary
  def summary
    @challenge = Challenge.find(params[:id])
  end

  private

  def require_challenge_creator
    unless current_user
      redirect_to challenges_path, alert: t("challenges.not_permitted_to_create")
      return
    end

    if current_user.challenges.any?
      redirect_to challenges_path, alert: t("challenges.already_enrolled_cannot_create")
    end
  end
end
